import logging
from dataclasses import dataclass
from typing import Optional, Tuple

import numpy as np
import torch
import torch.nn as nn
from skyfield.api import Angle, N, S, Star, W, load
from skyfield.data import hipparcos
from skyfield.named_stars import named_star_dict


def main():
    logging.basicConfig(level=logging.INFO)

    cf = CelestialFix()
    cf.add_observation("Arcturus", cf.ut1(2022, 3, 28, 0, 22, 33, tz=-5), dms(45.7))
    cf.add_observation("Polaris", cf.ut1(2022, 3, 28, 0, 21, 45, tz=-5), dms(45.6))
    cf.add_observation("Procyon", cf.ut1(2022, 3, 28, 0, 19, 51, tz=-5), dms(25.2))
    cf.fix()


def dms(degrees, minutes=0.0, seconds=0.0):
    return degrees + minutes / 60.0 + seconds / 3600.0


def norm_angle(angle):
    return Angle(degrees=np.mod(angle.degrees + 180.0, 2.0 * 180.0) - 180.0)


def format_coord(pos):
    lat, lon = pos[0], pos[1]
    lat_f = format_dm(lat, "N", "S")
    lon_f = format_dm(lon, "E", "W")
    return f"{lat_f} {lon_f}"


def format_dm(angle, pos="", neg="−"):
    side = pos if angle.degrees >= 0 else neg

    a = np.round(angle.degrees * 60.0 * 10.0) / (60.0 * 10.0)
    d, m_frac = divmod(abs(a), 1.0)
    m = m_frac * 60.0

    return "%3d°%04.1f′%s" % (d, m, side)


@dataclass
class ObservationParams:
    index_error_min: float = 0.0
    eye_height_m: float = 0.0
    semidiameter_correction_min: float = 0.0
    temperature_degC: float = 10.0
    pressure_Pa: float = 1010.0
    needs_correction: bool = True

    def corrected_altitude(self, alt_sextant):
        if not self.needs_correction:
            return alt_sextant

        alt_apparent_deg = (
            alt_sextant.degrees - self.index_error_min / 60.0 + self.dip_correction_m()
        )
        alt_observed_deg = (
            alt_apparent_deg
            + self.refraction_correction(alt_apparent_deg)
            + self.semidiameter_correction_min / 60.0
        )

        return Angle(degrees=alt_observed_deg)

    def dip_correction_m(self):
        # https://thenauticalalmanac.com/TNARegular/2022_Nautical_Almanac.pdf page 9
        minutes = 1.76 * np.sqrt(self.eye_height_m)

        return -minutes / 60.0

    def refraction_correction(self, alt_apparent_min):
        def cotd(a):
            return 1.0 / np.tan(np.deg2rad(a))

        # https://thenauticalalmanac.com/TNARegular/2022_Nautical_Almanac.pdf page 8
        # https://ur.booksc.eu/book/38210957/71b18e
        # The Calculation of Astronomical Refraction in Marine Navigation
        # Bennet, G. G., 1982
        minutes_mean = cotd(alt_apparent_min + 7.31 / (alt_apparent_min + 4.4))

        minutes = minutes_mean
        minutes *= (self.pressure_Pa - 80) / 930
        minutes /= 1 + 8e-5 * (minutes_mean + 30) * (self.temperature_degC - 10)

        return -minutes / 60.0


def coord_to_vector(pos):
    lat, lon = pos[0], pos[1]
    return coord_to_vector_m(np.array([[lat.radians, lon.radians]]).T)


def coord_to_vector_m(coord):
    cos_lat = np.cos(coord[0])
    x = np.cos(coord[1]) * cos_lat
    y = np.sin(coord[1]) * cos_lat
    z = np.sin(coord[0])

    return np.vstack((x, y, z))


def vector_to_coord(vec):
    if vec.shape != (3, 1):
        raise ValueError("Expected a 3x1 vector, got %s", vec)
    m = vector_to_coord_m(vec)

    lat = norm_angle(Angle(radians=m.item(0)))
    lon = norm_angle(Angle(radians=m.item(1)))

    return (lat, lon)


def vector_to_coord_m(vec):
    norm = np.linalg.norm(vec, axis=0)
    vec /= norm

    lat = np.arcsin(vec[2])
    lon = np.arctan2(vec[1], vec[0])

    return np.vstack((lat, lon))


# ps: A point on each plane
# ns: The normal of each plane
def plane_intersection(ps, ns):
    # (o − p_i) · n_i = 0

    # o · n_i − p_i · n_i = 0

    #                       [ n_1 · p_1 ]
    # [ n_1 n_2 n_3 ]^T o = [ n_2 · p_2 ]
    #                       [ n_3 · p_3 ]

    m = ns.T
    b = np.sum(ns * ps, axis=0, keepdims=True).T

    if np.linalg.matrix_rank(m) < 3:
        raise ValueError("No unique solution")

    return np.linalg.lstsq(m, b, rcond=None)[0]


@dataclass
class Observation:
    star: str
    gp: Tuple[Angle, Angle]
    alt: Angle
    mag: Optional[Angle] = None


@dataclass
class RhumbLineMovement:
    bearing: Angle
    speed_knots: float
    duration_hours: float

    def distance_nm(self):
        return self.speed_knots * self.duration_hours


class NavigationModel(nn.Module):
    """A local optimization model which takes observer movement into account."""

    R_NM = 360.0 * 60.0 / (2.0 * torch.pi)

    def __init__(self, starting_pos, log):
        super().__init__()

        self.log = log
        self.starting_lat = nn.Parameter(torch.tensor(starting_pos[0].radians))
        self.starting_lon = nn.Parameter(torch.tensor(starting_pos[1].radians))
        # Assume a small common error in all observations.
        self.observation_error = nn.Parameter(torch.tensor(0.0))

    def forward(self):
        positions = []
        dist_errors = []
        loss = torch.tensor(0.0)

        lat, lon = self.starting_lat, self.starting_lon
        positions.append((Angle(radians=lat.item()), Angle(radians=lon.item())))

        for item in self.log:
            if isinstance(item, Observation):
                gp_lat = torch.tensor(item.gp[0].radians)
                gp_lon = torch.tensor(item.gp[1].radians)
                alt_deg = torch.tensor(item.alt.degrees) + self.observation_error

                dist_nm = self.distance_to_circle_nm(
                    pos=(lat, lon), gp=(gp_lat, gp_lon), alt_deg=alt_deg
                )

                loss += torch.square(dist_nm)

                # Could use the magnetic heading as well; not sure if it's helpful. It
                # could be harmful given bad measurements. What weight factor to use?

                if False:
                    if item.mag is not None:
                        mag = self.angle_to_gp(pos=(lat, lon), gp=(gp_lat, gp_lon))
                        loss += torch.square(
                            torch.remainder(
                                torch.tensor(item.mag.degrees)
                                - torch.rad2deg(mag)
                                + 180.0,
                                2.0 * 180.0,
                            )
                            - 180.0
                        )

                dist_errors.append((item.star, dist_nm.item()))

            elif isinstance(item, RhumbLineMovement):
                lat, lon = self.move_rhumb(
                    origin=(lat, lon),
                    bearing_rad=torch.tensor(item.bearing.radians),
                    distance_nm=torch.tensor(item.distance_nm()),
                )
                positions.append((Angle(radians=lat.item()), Angle(radians=lon.item())))

            else:
                raise ValueError(f"Invalid log item: {item}")

        return (positions, dist_errors, loss)

    @classmethod
    def distance_to_circle_nm(cls, pos, gp, alt_deg):
        """The distance from pos to the circle of equal altitude"""
        return (90.0 - alt_deg) * 60.0 - cls.distance_to_gp_nm(pos, gp)

    @classmethod
    def distance_to_gp_nm(cls, pos, gp):
        """The distance from pos to the GP"""
        lat1, lon1 = pos[0], pos[1]
        lat2, lon2 = gp[0], gp[1]

        # https://www.movable-type.co.uk/scripts/latlong.html#ortho-dist

        dlat = lat2 - lat1
        dlon = lon2 - lon1

        a = torch.square(torch.sin(dlat / 2.0)) + (
            torch.cos(lat1) * torch.cos(lat2) * torch.square(torch.sin(dlon / 2.0))
        )
        distance_rad = 2.0 * torch.arctan2(torch.sqrt(a), torch.sqrt(1.0 - a))
        return torch.rad2deg(distance_rad) * 60.0

    @classmethod
    def angle_to_gp(cls, pos, gp):
        """The bearing from pos to the GP (in radians)"""
        lat1, lon1 = pos[0], pos[1]
        lat2, lon2 = gp[0], gp[1]

        # https://www.movable-type.co.uk/scripts/latlong.html#bearing
        y = torch.sin(lon2 - lon1) * torch.cos(lat2)
        x = torch.cos(lat1) * torch.sin(lat2) - torch.sin(lat1) * torch.cos(
            lat2
        ) * torch.cos(lon2 - lon1)
        return torch.arctan2(y, x)

    @classmethod
    def move_rhumb(cls, origin, bearing_rad, distance_nm):
        lat_o, lon_o = origin

        distance_r = distance_nm / cls.R_NM

        # https://www.movable-type.co.uk/scripts/latlong.html#rhumb-destination

        lat = lat_o + torch.cos(-bearing_rad) * distance_r
        if torch.abs(lat) > torch.pi / 2.0:
            raise ValueError(
                "Tried to go past a pole, origin: %s bearing: %s distance: %.1f NM"
                % (
                    format_coord(
                        (Angle(radians=lat_o.item()), Angle(radians=lon_o.item()))
                    ),
                    format_dm(Angle(radians=bearing_rad.item())),
                    distance_nm,
                )
            )

        mercator_lat_diff = torch.log(
            torch.tan(torch.pi / 4.0 + lat / 2.0)
            / torch.tan(torch.pi / 4.0 + lat_o / 2.0)
        )
        if abs(mercator_lat_diff) < 1e-12:
            lat_ratio = torch.cos(lat_o)
        else:
            lat_ratio = (lat - lat_o) / mercator_lat_diff

        lon = lon_o - torch.sin(-bearing_rad) * distance_r / lat_ratio

        return (lat, lon)


class CelestialFix:
    ephemeris = None
    stars_dataframe = None

    def __init__(self, observation_params=ObservationParams()):
        self.observation_params = observation_params

        self.logger = logging.getLogger("CelestialFix")

        if self.ephemeris is None:
            self.logger.info("Loading ephemeris")
            self.__class__.ephemeris = load("de421.bsp")

        if self.stars_dataframe is None:
            self.logger.info("Loading star catalog")
            with load.open(hipparcos.URL) as f:
                self.__class__.stars_dataframe = hipparcos.load_dataframe(f)

        self.ts = load.timescale()

        self.bearing = Angle(degrees=0.0)
        self.speed_knots = 0.0
        self.time = None
        self.log = []

    def set_bearing_speed(self, bearing_deg, speed_knots):
        self.bearing = Angle(degrees=bearing_deg)
        self.speed_knots = speed_knots

    def add_observation(
        self, star, time, alt_sextant, *, mag=None, observation_params=None
    ):
        alt_sextant = Angle(degrees=alt_sextant)
        if mag is not None:
            mag = Angle(degrees=mag)

        if observation_params is None:
            observation_params = self.observation_params

        if self.time is not None and self.speed_knots != 0.0:
            diff_hours = (time - self.time) * 24.0
            if diff_hours < 0.0:
                raise ValueError(
                    "Tried to go back in time (%s to %s)" % (self.time, time)
                )

            mov = RhumbLineMovement(
                bearing=self.bearing,
                speed_knots=self.speed_knots,
                duration_hours=diff_hours,
            )
            self.logger.info(
                "Adding movement: %s at %.1f knots for %.3f hours (%.1f NM)",
                format_dm(mov.bearing),
                mov.speed_knots,
                mov.duration_hours,
                mov.distance_nm(),
            )
            self.log.append(mov)
        self.time = time

        self.logger.info("Adding observation")
        self.logger.info("  %s: %s", star, time.ut1_strftime())

        alt_observed = observation_params.corrected_altitude(alt_sextant)
        self.logger.info(
            "  %s Hs: %s Ho: %s", star, format_dm(alt_sextant), format_dm(alt_observed)
        )

        gp = self.star_gp(star, time)
        self.logger.info("  %s GP: %s", star, format_coord(gp))
        self.logger.info(
            "  %s dist: %.1f NM", star, (90.0 - alt_observed.degrees) * 60.0
        )

        if mag is not None:
            self.logger.info("  %s mag: %s", star, format_dm(mag))

        obs = Observation(star=star, gp=gp, alt=alt_observed, mag=mag)
        self.log.append(obs)

    def fix(self):
        rough_pos = self.fix_global_rough()
        return self.fix_local_fine(rough_pos)

    def fix_global_rough(self):
        self.logger.info("Rough global fix")

        alts = np.zeros((1, 0))
        gps = np.zeros((2, 0))

        for item in self.log:
            if isinstance(item, Observation):
                alts = np.c_[alts, np.array(item.alt.radians)]
                gps = np.c_[gps, np.array([item.gp[0].radians, item.gp[1].radians])]

            elif isinstance(item, RhumbLineMovement):
                # Ignore movement.
                pass

            else:
                raise ValueError(f"Invalid log item: {item}")

        gp_vecs = coord_to_vector_m(gps)

        # A point on the plane whose intersection with the sphere is the circle of equal
        # altitude.
        ps = np.sin(alts) * gp_vecs

        point = plane_intersection(ps, gp_vecs)

        # With no errors, the point would be on a unit sphere. Project it onto one.
        norm = np.linalg.norm(point)
        self.logger.info("  Radius (1 is optimal): %f", norm)

        point /= norm

        pos = vector_to_coord(point)
        self.logger.info("  Plane intersection: %s", format_coord(pos))

        return pos

    def fix_local_fine(self, pos):
        self.logger.info("Fine local fix")

        model = NavigationModel(pos, self.log)
        optimizer = torch.optim.AdamW(model.parameters(), lr=1e-4, amsgrad=True)
        scheduler = torch.optim.lr_scheduler.ExponentialLR(optimizer, 0.99)

        losses = []
        for i in range(1000):
            optimizer.zero_grad()
            positions, dist_errors, loss = model()
            loss.backward()
            optimizer.step()
            scheduler.step()
            losses.append(loss.item())

        self.logger.debug("  Losses: %s", losses)
        self.logger.info("  Loss: %g (after %d iterations)", losses[-1], len(losses))
        # import matplotlib.pyplot as plt
        # plt.plot(losses)
        # plt.pause(15)

        e = Angle(degrees=model.observation_error.item())
        self.logger.info("  Estimated observation error: %s", format_dm(e, "↑", "↓"))

        self.logger.info(
            "  Circle of equal altitude distance "
            + f"error{'' if len(dist_errors) == 1 else 's'}:"
        )
        for star, d in dist_errors:
            self.logger.info("    %7.1f NM %s", d, star)

        self.logger.info(f"  Position{'' if len(positions) == 1 else 's'}:")
        for pos in positions:
            self.logger.info("    %s", format_coord(pos))

        return positions[-1]

    def ut1(self, year, month, day, hour=0, minute=0, second=0, *, tz=0):
        return self.ts.ut1(year, month, day, hour - tz, minute, second)

    def star_gp(self, star_name, time):
        earth = self.ephemeris["earth"]
        df = self.stars_dataframe.loc[named_star_dict[star_name]]
        if df is None:
            raise ValueError(f"Unknown star: {star_name}")
        star = Star.from_dataframe(df)
        astrometric = earth.at(time).observe(star)
        apparent = astrometric.apparent()
        ra, dec, _distance = apparent.radec("date")

        self.logger.debug("  GAST: %s", time.gast * 15.0)
        self.logger.debug("  RA:   %s", ra.hours * 15.0)

        gha = np.mod((time.gast - ra.hours) * 15.0, 360.0)
        self.logger.debug("  GHA:  %s", gha)

        lat = dec
        lon = norm_angle(Angle(degrees=-gha))

        return (lat, lon)


def test_coord_vector():
    table = [
        ((0.0, 0.0), (1.0, 0.0, 0.0)),
        ((0.0, 90.0), (0.0, 1.0, 0.0)),
        ((0.0, -270.0), (0.0, 1.0, 0.0)),
        ((0.0, 180.0), (-1.0, 0.0, 0.0)),
        ((0.0, -180.0), (-1.0, 0.0, 0.0)),
        ((0.0, 270.0), (0.0, -1.0, 0.0)),
        ((0.0, -90.0), (0.0, -1.0, 0.0)),
        ((90.0, 0.0), (0.0, 0.0, 1.0)),
        ((-90.0, 0.0), (0.0, 0.0, -1.0)),
        ((90.0, 42.0), (0.0, 0.0, 1.0)),
        ((-90.0, 42.0), (0.0, 0.0, -1.0)),
    ]

    for (lat_d, lon_d), (x, y, z) in table:
        lat_ex = Angle(degrees=lat_d)
        lon_ex = Angle(degrees=lon_d)
        vec_ex = np.array([[x, y, z]]).T

        print(f"{format_coord((lat_ex, lon_ex))} {vec_ex}")

        vec = coord_to_vector((lat_ex, lon_ex))
        assert np.allclose(vec, vec_ex)

        pos = vector_to_coord(vec_ex)
        print(format_coord(pos))
        vec_again = coord_to_vector(pos)
        assert np.allclose(vec_again, vec_ex)


def test_ut1_tz():
    cf = CelestialFix()
    assert cf.ut1(1982, 7, 18, 22, 37, 30, tz=-7) == cf.ut1(1982, 7, 19, 5, 37, 30)


def test_star_gp():
    cf = CelestialFix()
    table = [
        (
            "Regulus",
            cf.ut1(2018, 11, 15, 8, 28, 15),
            dms(11, 52.5) * N,
            (
                np.interp(
                    Angle(hours=(8, 28, 15)).hours,
                    [8, 9],
                    [dms(174, 21.6), dms(189, 24.0)],
                )
                + dms(207, 39.7)  # SHA
            )
            * W,
        ),
        (
            "Arcturus",
            cf.ut1(2018, 11, 15, 8, 30, 30),
            dms(19, 5.3) * N,
            (
                np.interp(
                    Angle(hours=(8, 30, 30)).hours,
                    [8, 9],
                    [dms(174, 21.6), dms(189, 24.0)],
                )
                + dms(145, 52.7)  # SHA
            )
            * W,
        ),
        (
            "Dubhe",
            cf.ut1(2018, 11, 15, 8, 32, 15),
            dms(61, 38.8) * N,
            (
                np.interp(
                    Angle(hours=(8, 32, 15)).hours,
                    [8, 9],
                    [dms(174, 21.6), dms(189, 24.0)],
                )
                + dms(193, 47.5)  # SHA
            )
            * W,
        ),
        (
            "Capella",
            cf.ut1(1982, 7, 21, 7, 55, 12, tz=-7),
            dms(45, 58.7) * N,
            (
                np.interp(
                    Angle(hours=(7 + 7, 55, 12)).hours,
                    [14, 15, 16],
                    [dms(149, 0.5), dms(164, 3.0), dms(179, 5.4)],
                )
                + dms(281, 9.7)  # SHA
            )
            * W,
        ),
        (
            "Vega",
            cf.ut1(1982, 7, 21, 8, 15, 12, tz=-7),
            dms(38, 46.1) * N,
            (
                np.interp(
                    Angle(hours=(8 + 7, 15, 12)).hours,
                    [14, 15, 16],
                    [dms(149, 0.5), dms(164, 3.0), dms(179, 5.4)],
                )
                + dms(80, 54.5)  # SHA
            )
            * W,
        ),
        (
            "Vega",
            cf.ut1(1982, 7, 18, 22, 37, 30, tz=-7),
            dms(38, 46.1) * N,
            (
                np.interp(
                    Angle(hours=(22 + 7 - 24, 37, 30)).hours,
                    [5, 6],
                    [dms(11, 40.0), dms(26, 42.5)],
                )
                + dms(80, 54.5)  # SHA
            )
            * W,
        ),
        (
            "Alkaid",
            cf.ut1(1982, 7, 18, 22, 40, 14, tz=-7),
            dms(49, 24.4) * N,
            (
                np.interp(
                    Angle(hours=(22 + 7 - 24, 40, 14)).hours,
                    [5, 6],
                    [dms(11, 40.0), dms(26, 42.5)],
                )
                + dms(153, 17.4)  # SHA
            )
            * W,
        ),
        (
            "Rigil Kentaurus",
            cf.ut1(1999, 3, 24, 23, 41, 56),
            dms(60, 49.7) * S,
            (dms(166, 58.3) + dms(10, 30.7) + dms(140, 6.2)) * W,
        ),
    ]

    for (star_name, time, lat_ex_d, lon_ex_d) in table:
        lat_ex = norm_angle(Angle(degrees=lat_ex_d))
        lon_ex = norm_angle(Angle(degrees=lon_ex_d))
        print(f"{star_name} {time} {format_coord((lat_ex, lon_ex))}")

        lat, lon = cf.star_gp(star_name, time)
        assert abs((lat_ex.degrees - lat.degrees) * 600.0) < 1
        assert abs((lon_ex.degrees - lon.degrees) * 600.0) < 1


def test_fix_1():
    # https://mctoon.net/10000-flat-earth-sextant-challenge/
    #
    # Observation date: November 15, 2018
    # Instrument used: sextant
    # Method: angle between star and horizon
    # Eye Height: 2 meters
    # Index Error: +0.3′
    # True Bearing: 0°
    # Speed: 12 kn
    # Temperature: 12C
    # Barometric Pressure: 975 millibars
    # Regulus: 70°48.7′  at 8:28:15 GMT
    # Arcturus: 27°9.0′  at 8:30:30 GMT
    # Dubhe: 55°18.4′  at 8:32:15 GMT

    # Official fix: 29°40.5′N 36°57.0′W

    # This test case ignores the movement of the ship and is off from the official fix.
    cf = CelestialFix(
        ObservationParams(
            index_error_min=0.3, eye_height_m=2, temperature_degC=12, pressure_Pa=975
        )
    )
    cf.set_bearing_speed(0.0, 12.0)
    cf.add_observation("Regulus", cf.ut1(2018, 11, 15, 8, 28, 15), dms(70, 48.7))
    cf.add_observation("Arcturus", cf.ut1(2018, 11, 15, 8, 30, 30), dms(27, 9.0))
    cf.add_observation("Dubhe", cf.ut1(2018, 11, 15, 8, 32, 15), dms(55, 18.4))
    assert format_coord(cf.fix()) == " 29°41.0′N  36°57.3′W"


def test_fix_2():
    # https://youtu.be/Yh9SV3nAyRw
    # Celestial Exercise for Part 14: A complete Twilight Planning and Shooting
    # Leon Schulz, Reginasailing

    # Official fix which also includes Venus but ignores Rigel as a bad observation:
    # 29°56′N 14°20′W

    cf = CelestialFix(ObservationParams(index_error_min=2, eye_height_m=3))
    cf.add_observation("Dubhe", cf.ut1(2020, 10, 15, 6, 28, 7), dms(40, 34))
    cf.add_observation("Rigel", cf.ut1(2020, 10, 15, 6, 37, 9), dms(42, 7))
    cf.add_observation("Aldebaran", cf.ut1(2020, 10, 15, 6, 41, 11), dms(50, 25))
    cf.add_observation("Polaris", cf.ut1(2020, 10, 15, 6, 43, 0), dms(30, 18))
    # TODO: Venus
    assert format_coord(cf.fix()) == " 29°55.7′N  14°20.4′W"


def test_fix_3():
    # https://youtu.be/J7XmHIjKaP4
    # https://youtu.be/YcYdrEFDD5g
    # Celestial Navigation Challenge
    # Science It Out

    # Location 1:
    # Alkaid – 56°07’03.3”
    # Capella – 33°42’42.5”
    # Alphard – 38°05’46.3”
    # Time: 2021-12-17 10:35:27 UTC

    # Official fix: 40°28.8′N 85°05.9′W

    cf = CelestialFix()
    cf.add_observation("Alkaid", cf.ut1(2021, 12, 17, 10, 35, 27), dms(56, 7, 3.3))
    cf.add_observation("Capella", cf.ut1(2021, 12, 17, 10, 35, 27), dms(33, 42, 42.5))
    cf.add_observation("Alphard", cf.ut1(2021, 12, 17, 10, 35, 27), dms(38, 5, 46.3))
    assert format_coord(cf.fix()) == " 40°28.8′N  85°05.7′W"


def test_fix_4():
    # https://youtu.be/iB8xlWNhsn0
    # Global Navigation Challenge
    # MCToon

    # 2022-03-28, UTC-5
    # Procyon:  24.2° at 00:19:51
    # Polaris:  45.6° at 00:21:45
    # Arcturus: 45.7° at 00:22:33

    # Official fix only given truncated to one decimal place: 46.6°N, 93.3°W.
    # That could be anywhere between 46°36′N 93°18′W and 46°42′N 93°24′W.

    cf = CelestialFix()
    cf.add_observation(
        "Procyon", cf.ut1(2022, 3, 28, 0, 19, 51, tz=-5), dms(25.2), mag=dms(248)
    )
    cf.add_observation(
        "Polaris", cf.ut1(2022, 3, 28, 0, 21, 45, tz=-5), dms(45.6), mag=dms(355)
    )
    cf.add_observation(
        "Arcturus", cf.ut1(2022, 3, 28, 0, 22, 33, tz=-5), dms(45.7), mag=dms(118)
    )
    assert format_coord(cf.fix()) == " 46°36.5′N  93°21.4′W"


def test_fix_5():
    def feet_to_m(feet):
        return feet * 0.3048

    # Official fix: 54°2′S 74°45′W

    cf = CelestialFix(ObservationParams(index_error_min=2.5, eye_height_m=feet_to_m(9)))
    # http://www.efalk.org/Navigation/leg57-1.html
    cf.set_bearing_speed(119.3, 10.3)
    # http://www.efalk.org/Navigation/leg57-4.html
    cf.add_observation(
        "Rigil Kentaurus", cf.ut1(1999, 3, 24, 23, 41, 56), dms(35, 14.8)
    )
    # http://www.efalk.org/Navigation/leg57-5.html
    cf.add_observation("Acrux", cf.ut1(1999, 3, 24, 23, 42, 6), dms(48, 40.2))
    # http://www.efalk.org/Navigation/leg57-6.html
    cf.add_observation("Aldebaran", cf.ut1(1999, 3, 24, 23, 43, 12), dms(13, 51.6))
    # http://www.efalk.org/Navigation/leg57-7.html
    cf.add_observation("Peacock", cf.ut1(1999, 3, 24, 23, 45, 22), dms(22, 24.8))
    assert format_coord(cf.fix()) == " 54°00.1′S  74°44.8′W"


def test_fix_6():
    # https://www.youtube.com/watch?v=YiMjG8SMXCY&lc=UgzJXGXJ8vVE5u5r4u54AaABAg.9_cJ7WrdQ_m9_cKe8JTGz3

    cf = CelestialFix()
    cf.add_observation(
        "Dubhe",
        cf.ut1(2022, 4, 9, 0, 28, 0, tz=-4),
        dms(64, 41.5),
        mag=dms(337, 2.5),
    )
    cf.add_observation(
        "Regulus",
        cf.ut1(2022, 4, 9, 0, 30, 0, tz=-4),
        dms(48, 30.5),
        mag=dms(237, 45.0),
    )
    cf.add_observation(
        "Arcturus",
        cf.ut1(2022, 4, 9, 0, 32, 0, tz=-4),
        dms(59, 23.6),
        mag=dms(124, 33.2),
    )
    assert format_coord(cf.fix()) == " 39°38.6′N  77°34.7′W"


if __name__ == "__main__":
    main()
