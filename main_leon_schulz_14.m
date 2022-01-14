clear all;

% https://youtu.be/Yh9SV3nAyRw
% Celestial Exercise for Part 14: A complete Twilight Planning and Shooting
% Leon Schulz, Reginasailing

% 2020-08-15

position = coord_to_vector(from_dm(30, 14), -from_dm(14, 15));

index_error = from_dm(0, 2);
eye_height = from_meters(3);

observation_times = zeros(1, 0);
observation_alts  = zeros(1, 0);
observation_GPs   = zeros(3, 0);

% Dubhe
observation_times(end + 1) = [ 6, 28, 07 ] * (60 .^ [ 0; -1; -2 ]);
observation_alts(end + 1) = corrected_altitude(
  from_dm(40, 34), index_error, eye_height, 0);
observation_GPs(:, end + 1) = coord_to_vector(
  from_dm(61, 38.3),
  -(from_dm(114, 13.8) + from_dm(7, 02.9) + from_dm(193, 45.9)));

% Rigel
observation_times(end + 1) = [ 6, 37, 09 ] * (60 .^ [ 0; -1; -2 ]);
observation_alts(end + 1) = corrected_altitude(
  from_dm(42, 07), index_error, eye_height, 0);
observation_GPs(:, end + 1) = coord_to_vector(
  -from_dm(8, 10.6),
  -(from_dm(114, 13.8) + from_dm(9, 18.8) + from_dm(281, 07.0)));

% Aldebaran
observation_times(end + 1) = [ 6, 41, 11 ] * (60 .^ [ 0; -1; -2 ]);
observation_alts(end + 1) = corrected_altitude(
  from_dm(50, 25), index_error, eye_height, 0);
observation_GPs(:, end + 1) = coord_to_vector(
  from_dm(16, 33.0),
  -(from_dm(114, 13.8) + from_dm(10, 19.4) + from_dm(290, 43.3)));

% Polaris
observation_times(end + 1) = [ 6, 43, 00 ] * (60 .^ [ 0; -1; -2 ]);
observation_alts(end + 1) = corrected_altitude(
  from_dm(30, 18), index_error, eye_height, 0);
observation_GPs(:, end + 1) = coord_to_vector(
  from_dm(89, 20.9),
  -(from_dm(114, 13.8) + from_dm(10, 46.8) + from_dm(315, 09.2)));

% Venus
observation_times(end + 1) = [ 6, 45, 05 ] * (60 .^ [ 0; -1; -2 ]);
observation_alts(end + 1) = corrected_altitude(
  from_dm(33, 43), index_error, eye_height, from_dm(0, 0.1));
observation_GPs(:, end + 1) = coord_to_vector(
  from_dm(7, 1.0) - from_dm(0, 0.8),
  -(from_dm(308, 00.8) + from_dm(11, 16.3) - from_dm(0, 0.2)));

printf("Initial position: %s\n", vector_str(position));

position = position_fix(position, observation_GPs, observation_alts);
