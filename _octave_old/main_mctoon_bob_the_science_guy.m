clear all;

% https://youtu.be/Zex4F1g1Lts
% Teaching Nathan a Lesson in Navigation
% Bob the Science Guy
% Challenge provided by MCToon

% Star 1: Capella
% Time: 7:55:12 - 21 July 1982
% UTC-7; UTC time: 14:55:12
% Sextant Reading: 28 degrees 50.2 minutes

% Star 2: Vega
% Time: 8:15:22 - 21 July 1982
% UTC-7; UTC time: 15:15:22
% Sextant Reading: 10 degrees 56.1 minutes

% No more than 1200 miles from Hawaii.
% 9 feet above the water.
% Index error: 0

% Bearing: 232 degrees
% Speed: 7.6 knots

course = from_dm(232, 0);
speed = from_knots(7.6);

hawaii = coord_to_vector(from_dm(21, 18), -from_dm(157, 49));

capella_sextant_alt = from_dm(28, 50.2);
vega_sextant_alt    = from_dm(10, 56.1);

capella_time = [ 14, 55, 12 ] * (60 .^ [ 0; -1; -2 ]);
vega_time    = [ 15, 15, 22 ] * (60 .^ [ 0; -1; -2 ]);

eye_height = from_feet(9);

capella_observed_alt = corrected_altitude(capella_sextant_alt, 0, eye_height, 0);
vega_observed_alt    = corrected_altitude(vega_sextant_alt,    0, eye_height, 0);

printf("Capella Hs, Ho: %s %s\n", dm_str(capella_sextant_alt), dm_str(capella_observed_alt));
printf("Vega Hs, Ho:    %s %s\n", dm_str(vega_sextant_alt),    dm_str(vega_observed_alt));

% https://www.tecepe.com.br/scripts/AlmanacPagesISAPI.dll/pages?date=07%2F21%2F1982
aries_GHA_t = [
  14 from_dm(149, 0.5)
  15 from_dm(164, 3.0)
  16 from_dm(179, 5.4)
];
aries_GHA_14_55_12 = interp1(aries_GHA_t(:, 1), aries_GHA_t(:, 2), capella_time);
aries_GHA_15_15_22 = interp1(aries_GHA_t(:, 1), aries_GHA_t(:, 2), vega_time);

capella_SHA = from_dm(281,  9.7);
capella_dec = from_dm( 45, 58.7);
vega_SHA    = from_dm( 80, 54.5);
vega_dec    = from_dm( 38, 46.1);

capella_GHA = aries_GHA_14_55_12 + capella_SHA;
vega_GHA    = aries_GHA_15_15_22 + vega_SHA;

% A positive longitude is toward the East, a positive GHA is toward the West.
% https://astronavigationdemystified.com/translating-a-celestial-position-into-a-geographical-position/
capella_GP = coord_to_vector(capella_dec, -capella_GHA);
vega_GP    = coord_to_vector(vega_dec,    -vega_GHA);

printf("Capella GP: %s\n", vector_str(capella_GP));
printf("Vega GP:    %s\n", vector_str(vega_GP));

observation_GPs  = [ capella_GP,           vega_GP ];
observation_alts = [ capella_observed_alt, vega_observed_alt ];

position = hawaii;
printf("Initial position: %s\n", vector_str(position));

printf("\nInitial fix (not taking movement into account):\n");

% Get an initial estimate ignoring the movement between the observations.
position = position_fix_rough(position, observation_GPs, observation_alts);

printf("\nSight reduction:\n");

courses   = [ course ];
distances = [ speed * (vega_time - capella_time) ];

position = sight_reduction(
  position, courses, distances, observation_GPs, observation_alts);

printf("\nResult:\n");
printf("Position: %s\n", vector_str(position));
