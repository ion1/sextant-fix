clear all;

# https://mctoon.net/sextant-debate/
# https://mctoon27.files.wordpress.com/2022/01/sextant-challenge.pdf
# https://mctoon27.files.wordpress.com/2022/01/sextant-solution.pdf

# July 18, 1982
# You only know you are within 1200 miles of Hawaii.
# Your boat is traveling on a heading of 252° at 6.9 knots.

# You take sextant readings of 2 stars from an eye height of 9 feet:

# Vega:    Time = 22:37:30  Sextant Reading = 47° 22.5’
# Alkaid:  Time = 22:40:14  Sextant Reading = 59° 14.0’

# Your watch’s Zone Description is +7 hours (UTC = WT+7)
# The index correction and watch error are both zero.

# Official fix: 25° 15.0’ N, 150° 25.9’ W

# In UTC time:
# July 19, 1982
# Vega:    Time = 05:37:30  Sextant Reading = 47° 22.5’
# Alkaid:  Time = 05:40:14  Sextant Reading = 59° 14.0’

course = from_dm(252, 0);
speed_kn = 6.9;
# Speed in radians/hour.
speed = speed_kn * 1.852 / 6371;

hawaii = coord_to_vector(from_dm(21, 18), -from_dm(157, 49));
official_position = coord_to_vector(from_dm(25, 15.0), -from_dm(150, 25.9));

vega_sextant_alt   = from_dm(47, 22.5);
alkaid_sextant_alt = from_dm(59, 14.0);

vega_time   = [ 5, 37, 30 ] * (60 .^ [ 0; -1; -2 ]);
alkaid_time = [ 5, 40, 14 ] * (60 .^ [ 0; -1; -2 ]);

eye_height_ft = 9;

vega_observed_alt   = corrected_altitude(vega_sextant_alt,   0, eye_height_ft, 0);
alkaid_observed_alt = corrected_altitude(alkaid_sextant_alt, 0, eye_height_ft, 0);

printf("Vega   Hs, Ho: %s %s\n", dm_str(vega_sextant_alt),   dm_str(vega_observed_alt));
printf("Alkaid Hs, Ho: %s %s\n", dm_str(alkaid_sextant_alt), dm_str(alkaid_observed_alt));

# https://www.tecepe.com.br/scripts/AlmanacPagesISAPI.dll/pages?date=07%2F19%2F1982
# https://thenauticalalmanac.com/TNARegular/2022_Nautical_Almanac.pdf pages 262–281
aries_GHA_05_37_30 = from_dm(11, 40.0) + from_dm( 9, 24.0);
aries_GHA_05_40_14 = from_dm(11, 40.0) + from_dm(10,  3.5);

vega_SHA   = from_dm( 80, 54.5);
vega_dec   = from_dm( 38, 46.1);
alkaid_SHA = from_dm(153, 17.4);
alkaid_dec = from_dm( 49, 24.4);

vega_GHA   = aries_GHA_05_37_30 + vega_SHA;
alkaid_GHA = aries_GHA_05_40_14 + alkaid_SHA;

# A positive longitude is toward the East, a positive GHA is toward the West.
# https://astronavigationdemystified.com/translating-a-celestial-position-into-a-geographical-position/
vega_GP   = coord_to_vector(vega_dec,   -vega_GHA);
alkaid_GP = coord_to_vector(alkaid_dec, -alkaid_GHA);

printf("Vega GP:   %s\n", vector_str(vega_GP));
printf("Alkaid GP: %s\n", vector_str(alkaid_GP));

printf("\nInitial fix (not taking movement into account):\n");
# Get an initial estimate ignoring the movement between the observations.
initial_fixes = position_fix(
  vega_GP,   vega_observed_alt,
  alkaid_GP, alkaid_observed_alt);

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
distances        = [ speed * (alkaid_time - vega_time) ];
observation_GPs  = [ vega_GP,           alkaid_GP ];
observation_alts = [ vega_observed_alt, alkaid_observed_alt ];

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

printf("Official: %s\n", vector_str(official_position));
[ azimuth, distance ] = azimuth_distance(position, official_position);
printf("  Bearing: %s, distance: %s\n", dm_str(azimuth), dm_str(distance));
