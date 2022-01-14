clear all;

% http://www.efalk.org/Navigation/leg57-1.html

initial_position = coord_to_vector(-from_dm(51, 30.0), -from_dm(80, 59.5));
printf("Initial position: %s\n", vector_str(initial_position));

initial_time = [  0, 10, 23 ] * (60 .^ [ 0; -1; -2 ]);
final_time   = [ 23, 41, 56 ] * (60 .^ [ 0; -1; -2 ]);
speed = from_knots(10.3);
distance = (final_time - initial_time) * speed;
course = deg2rad(119.3);
eye_height = from_feet(9);

position = move_constant_bearing(initial_position, course, distance);
% The value in the document.
%position = coord_to_vector(-from_dm(53, 38.4), -from_dm(74, 44.6));

print_new_position(initial_position, position);

observation_times = zeros(1, 0);
observation_alts  = zeros(1, 0);
observation_GPs   = zeros(3, 0);

% https://thenauticalalmanac.com/TNARegular/1999_Nautical_Almanac.pdf

% http://www.efalk.org/Navigation/leg57-4.html
% Rigil Kentaurus
% 1999-03-24 23:41:56
observation_times(end + 1) = [ 23, 41, 56 ] * (60 .^ [ 0; -1; -2 ]);
observation_alts(end + 1) = ...
  corrected_altitude(from_dm(35, 14.8), from_dm(0, 2.5), eye_height, 0);
observation_GPs(:, end + 1) = coord_to_vector(
  -from_dm(60, 49.7),
  -(from_dm(166, 58.3) + from_dm(10, 30.7) + from_dm(140, 6.2)));

% http://www.efalk.org/Navigation/leg57-5.html
% Acrux
% 1999-03-24 23:42:06
observation_times(end + 1) = [ 23, 42, 06 ] * (60 .^ [ 0; -1; -2 ]);
observation_alts(end + 1) = ...
  corrected_altitude(from_dm(48, 40.2), from_dm(0, 2.5), eye_height, 0);
observation_GPs(:, end + 1) = coord_to_vector(
  -from_dm(63, 5.6),
  -(from_dm(166, 58.3) + from_dm(10, 31.5) + from_dm(173, 21.0)));

% http://www.efalk.org/Navigation/leg57-6.html
% Aldebaran
% 1999-03-24 23:43:12
observation_times(end + 1) = [ 23, 43, 12 ] * (60 .^ [ 0; -1; -2 ]);
observation_alts(end + 1) = ...
  corrected_altitude(from_dm(13, 51.6), from_dm(0, 2.5), eye_height, 0);
observation_GPs(:, end + 1) = coord_to_vector(
  from_dm(16, 30.3),
  -(from_dm(166, 58.3) + from_dm(10, 48.0) + from_dm(291, 2.2)));

% http://www.efalk.org/Navigation/leg57-7.html
% Peacock
% 1999-03-24 23:45:22
observation_times(end + 1) = [ 23, 45, 22 ] * (60 .^ [ 0; -1; -2 ]);
observation_alts(end + 1) = ...
  corrected_altitude(from_dm(22, 24.8), from_dm(0, 2.5), eye_height, 0);
observation_GPs(:, end + 1) = coord_to_vector(
  -from_dm(56, 44.1),
  -(from_dm(166, 58.3) + from_dm(11, 20.5) + from_dm(53, 36.9)));

distances = speed * [ zeros(1, 0), diff(observation_times) ];
courses   = course * ones(1, columns(distances));

position = sight_reduction(
  position, courses, distances, observation_GPs, observation_alts);
