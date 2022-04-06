clear all;

% https://youtu.be/vmpzm-1qqrI
% Sextant to Line of Position - A Complete Sight Reduction from an Offshore Sailing Race
% Practical Navigator

% 2021-05-29 20:07:30 UTC
% Sun's lower limb
% Eye height: 8 feet
% Index error: 1 minute

% https://thenauticalalmanac.com/TNARegular/2021_Nautical_Almanac.pdf
% pages 116 and 264
sun_GHA = from_dm(120, 37.8) + from_dm(1, 52.5);
sun_dec = from_dm( 21, 44.7) + from_dm(0,  0.4) * ([ 7, 30 ] * (60 .^ [ -1; -2 ]));
sun_SD  = from_dm(0, 15.8);

index_error = from_dm(0, 1);
eye_height = from_feet(8);

Hs = from_dm(51, 6.6);
Ho = corrected_altitude(Hs, index_error, eye_height, sun_SD);

DR = coord_to_vector(from_dm(32, 0), -from_dm(80, 0));
sun_GP = coord_to_vector(sun_dec, -sun_GHA);

printf("DR:     %s\n", vector_str(DR));
printf("Sun GP: %s\n", vector_str(sun_GP));

position = DR;
courses   = zeros(1, 0);
distances = zeros(1, 0);
observation_GPs  = [ sun_GP ];
observation_alts = [ Ho ];

position = sight_reduction(
  position, courses, distances, observation_GPs, observation_alts);
