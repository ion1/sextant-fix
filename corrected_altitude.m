% sextant_altitude: The sighted altitude from the sextant
% index_error: The index error of the sextant
% eye_height_m: The height of the observer in meters
% semidiameter_correction: Positive for the lower limb, negative for the upper limb
% observed_altitude: The corrected altitude
function observed_altitude = corrected_altitude(
  sextant_altitude, index_error, eye_height_m, semidiameter_correction=0,
  temperature=10, pressure=1010)

  apparent_altitude = sextant_altitude ...
                    - index_error ...
                    + dip_correction_m(eye_height_m);
  observed_altitude = apparent_altitude ...
                    + refraction_correction(apparent_altitude, temperature, pressure) ...
                    + semidiameter_correction;
endfunction

function correction_angle = dip_correction_m(eye_height_m)
  % https://thenauticalalmanac.com/TNARegular/2022_Nautical_Almanac.pdf page 9
  correction_angle = -from_dm(0, 1.76 * sqrt(eye_height_m));
endfunction

function correction_angle = refraction_correction(
  apparent_altitude, temperature=10, pressure=1010)

  % https://thenauticalalmanac.com/TNARegular/2022_Nautical_Almanac.pdf page 8
  % https://ur.booksc.eu/book/38210957/71b18e
  % The Calculation of Astronomical Refraction in Marine Navigation
  % Bennet, G. G., 1982
  Ha = rad2deg(apparent_altitude);
  minutes_mean = cotd(Ha + 7.31 / (Ha + 4.4));

  minutes = minutes_mean;
  minutes *= (pressure - 80) / 930;
  minutes /= 1 + 8e-5 * (minutes_mean + 30) * (temperature - 10);

  correction_angle = -from_dm(0, minutes);
endfunction
