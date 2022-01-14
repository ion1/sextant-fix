clear all;

% https://youtu.be/eLKNiYj5V-s
% Celestial Exercise for Part 9: Plotting a Position
% Leon Schulz, Reginasailing

% 2020-12-17

position = coord_to_vector(from_dm(14, 2), -from_dm(52, 11));
course = deg2rad(271);
speed = from_knots(8);

index_error = from_dm(0, 4);
eye_height  = from_meters(2.8);

observation_times = zeros(1, 0);
observation_alts  = zeros(1, 0);
observation_GPs   = zeros(3, 0);

observation_times(end + 1) = [ 11, 45, 11 ] * (60 .^ [ 0; -1; -2 ]);
observation_alts(end + 1) = corrected_altitude(
  from_dm(24, 35), index_error, eye_height, from_dm(0, 16.2));
observation_GPs(:, end + 1) = coord_to_vector(
  -from_dm(23, 22.6), -(from_dm(345, 55.5) + from_dm(11, 17.7)));

observation_times(end + 1) = [ 15, 30, 0 ] * (60 .^ [ 0; -1; -2 ]);
observation_alts(end + 1) = corrected_altitude(
  from_dm(52, 22), index_error, eye_height, from_dm(0, 16.2));
observation_GPs(:, end + 1) = coord_to_vector(
  -from_dm(23, 22.8), -(from_dm(45, 54.3) + from_dm(7, 30.0)));

distances = speed * [ zeros(1, 0), diff(observation_times) ];
courses   = course * ones(1, columns(distances));

printf("Initial position: %s\n", vector_str(position));

position = sight_reduction(
  position, courses, distances, observation_GPs, observation_alts);
