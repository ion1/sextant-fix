clear all;
# TODO: How to get this to load on repl.it?
pkg load quaternion;

# Star 1: Capella
# Time: 7:55:12 - 21 July 1982
# UTC-7; UTC time: 14:55:12
# Sextant Reading: 28 degrees 50.2 minutes

# Star 2: Vega
# Time: 8:15:22 - 21 July 1982
# UTC-7; UTC time: 15:15:22
# Sextant Reading: 10 degrees 56.1 minutes

# Course: 232 degrees
# Speed: 7.6 knots

# No more than 1200 miles from Hawaii.
# 9 feet above the water.
# Index error: 0

course = from_dm(232, 0);
speed_kn = 7.6;
# Speed in radians/hour.
speed = speed_kn * 1.852 / 6371;

hawaii = coord_to_vector(from_dm(21, 18), -from_dm(157, 49));

capella_sextant_alt = from_dm(28, 50.2);
vega_sextant_alt    = from_dm(10, 56.1);

capella_time = [ 14, 55, 12 ] * (60 .^ [ 0; -1; -2 ]);
vega_time    = [ 15, 15, 22 ] * (60 .^ [ 0; -1; -2 ]);

eye_height_ft = 9;

capella_observed_alt = corrected_altitude(capella_sextant_alt, 0, eye_height_ft, 0);
vega_observed_alt    = corrected_altitude(vega_sextant_alt,    0, eye_height_ft, 0);

printf("Capella Ho: %s\n", dm_str(capella_observed_alt));
printf("Vega Ho:    %s\n",   dm_str(vega_observed_alt));

# https://www.tecepe.com.br/scripts/AlmanacPagesISAPI.dll/pages?date=07%2F21%2F1982
# https://thenauticalalmanac.com/TNARegular/2022_Nautical_Almanac.pdf pages 262–281
aries_GHA_14_55_12 = from_dm(149, 0.5) + from_dm(13, 50.3);
aries_GHA_15_15_22 = from_dm(164, 3.0) + from_dm( 3, 51.1);

capella_SHA = from_dm(281,  9.7);
capella_dec = from_dm( 45, 58.7);
vega_SHA    = from_dm( 80, 54.5);
vega_dec    = from_dm( 38, 46.1);

capella_GHA = aries_GHA_14_55_12 + capella_SHA;
vega_GHA    = aries_GHA_15_15_22 + vega_SHA;

# A positive longitude is toward the East, a positive GHA is toward the West.
# https://astronavigationdemystified.com/translating-a-celestial-position-into-a-geographical-position/
capella_GP = coord_to_vector(capella_dec, -capella_GHA);
vega_GP    = coord_to_vector(vega_dec,    -vega_GHA);

printf("Capella GP: %s\n", vector_str(capella_GP));
printf("Vega GP:    %s\n", vector_str(vega_GP));

printf("\nInitial fix (not taking movement into account):\n");
# Get an initial estimate ignoring the movement between the observations.
initial_fixes = position_fix(
  capella_GP, capella_observed_alt,
  vega_GP,    vega_observed_alt);

for i = 1:columns(initial_fixes)
  position = initial_fixes(:, i);
  printf("  Fix %d: %s\n", i, vector_str(position));
endfor

[ _, initial_fix_ix ] = min(norm(initial_fixes .- hawaii, "cols"));

printf("Choosing initial fix %d\n", initial_fix_ix);
initial_fix = initial_fixes(:, initial_fix_ix);

printf("\nSight reduction:\n");

position = initial_fix;

printf("Initial position: %s\n", vector_str(position));

courses          = [ course ];
distances        = [ speed * (vega_time - capella_time) ];
observation_GPs  = [ capella_GP,           vega_GP ];
observation_alts = [ capella_observed_alt, vega_observed_alt ];

[ position, circle_normals ] = sight_reduction(
  position, courses, distances, observation_GPs, observation_alts);

printf("\nFinal fix:\n");

fixes = position_fix(
  circle_normals(:, 1), observation_alts(1),
  circle_normals(:, 2), observation_alts(2));

for i = 1:columns(fixes)
  printf("  Fix %d: %s\n", i, vector_str(fixes(:, i)));
endfor

[ _, fix_ix ] = min(norm(fixes .- initial_fix, "cols"));

printf("Choosing fix %d\n", fix_ix);

position = fixes(:, fix_ix);

printf("\nResult:\n");
printf("Position: %s\n", vector_str(position));
