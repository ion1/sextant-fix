clear all;

% https://mctoon.net/10000-flat-earth-sextant-challenge/

% Observation date: November 15, 2018
% Instrument used: sextant
% Method: angle between star and horizon
% Eye Height: 2 meters
% Index Error: +0.3′
% True Bearing: 0°
% Speed: 12 kn
% Temperature: 12C
% Barometric Pressure: 975 millibars
% Regulus: 70°48.7′  at 8:28:15 GMT
% Arcturus: 27°9.0′  at 8:30:30 GMT
% Dubhe: 55°18.4′  at 8:32:15 GMT

% Official result: 29°40.5′N 36°57.0′W

course = from_dm(0, 0);
speed = from_knots(12);

regulus_sextant_alt  = from_dm(70, 48.7);
arcturus_sextant_alt = from_dm(27, 09.0);
dubhe_sextant_alt    = from_dm(55, 18.4);

regulus_time  = from_hms(8, 28, 15);
arcturus_time = from_hms(8, 30, 30);
dubhe_time    = from_hms(8, 32, 15);

index_error = from_dm(0, 0.3);
eye_height  = from_meters(2);
temperature = 12;
pressure    = 975;

regulus_observed_alt  = corrected_altitude(regulus_sextant_alt,  index_error, eye_height, 0, temperature, pressure);
arcturus_observed_alt = corrected_altitude(arcturus_sextant_alt, index_error, eye_height, 0, temperature, pressure);
dubhe_observed_alt    = corrected_altitude(dubhe_sextant_alt,    index_error, eye_height, 0, temperature, pressure);

printf("Regulus  Hs, Ho: %s %s\n", dm_str(regulus_sextant_alt),  dm_str(regulus_observed_alt));
printf("Arcturus Hs, Ho: %s %s\n", dm_str(arcturus_sextant_alt), dm_str(arcturus_observed_alt));
printf("Dubhe    Hs, Ho: %s %s\n", dm_str(dubhe_sextant_alt),    dm_str(dubhe_observed_alt));

% https://thenauticalalmanac.com/TNARegular/2018_Nautical_Almanac.pdf page 230
aries_GHA_t = [
  8 from_dm(174, 21.6)
  9 from_dm(189, 24.0)
];
aries_GHA_08_28_15 = interp1(aries_GHA_t(:, 1), aries_GHA_t(:, 2), regulus_time);
aries_GHA_08_30_30 = interp1(aries_GHA_t(:, 1), aries_GHA_t(:, 2), arcturus_time);
aries_GHA_08_32_15 = interp1(aries_GHA_t(:, 1), aries_GHA_t(:, 2), dubhe_time);

regulus_SHA  = from_dm(207, 39.7);
regulus_dec  = from_dm( 11, 52.5);
arcturus_SHA = from_dm(145, 52.7);
arcturus_dec = from_dm( 19, 05.3);
dubhe_SHA    = from_dm(193, 47.5);
dubhe_dec    = from_dm( 61, 38.8);

regulus_GHA  = aries_GHA_08_28_15 + regulus_SHA;
arcturus_GHA = aries_GHA_08_30_30 + arcturus_SHA;
dubhe_GHA    = aries_GHA_08_32_15 + dubhe_SHA;

% A positive longitude is toward the East, a positive GHA is toward the West.
% https://astronavigationdemystified.com/translating-a-celestial-position-into-a-geographical-position/
regulus_GP  = coord_to_vector(regulus_dec,  -regulus_GHA);
arcturus_GP = coord_to_vector(arcturus_dec, -arcturus_GHA);
dubhe_GP    = coord_to_vector(dubhe_dec,    -dubhe_GHA);

printf("Regulus GP:  %s\n", vector_str(regulus_GP));
printf("Arcturus GP: %s\n", vector_str(arcturus_GP));
printf("Dubhe GP:    %s\n", vector_str(dubhe_GP));

observation_GPs  = [ regulus_GP, arcturus_GP, dubhe_GP ];
observation_alts = [ regulus_observed_alt, arcturus_observed_alt, dubhe_observed_alt ];

printf("\nInitial fix (not taking movement into account):\n");

% Get an initial estimate ignoring the movement between the observations.
position = position_fix_rough([0; 0; 0], observation_GPs, observation_alts);

printf("\nSight reduction:\n");

times = [ regulus_time, arcturus_time, dubhe_time ];
courses = repmat(course, 1, length(times) - 1);
distances = speed * (times(2 : end) - times(1 : end-1));

position = sight_reduction(
  position, courses, distances, observation_GPs, observation_alts);

printf("\nResult:\n");
printf("Position: %s\n", vector_str(position));
