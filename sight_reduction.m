% circle_normals: The normals of the circles whose intersection is the position
% position: The initial/final position of the observer
% courses: The course between each observation
% distances: The distance travelled between each observation
% observation_GPs: The geographical points of the stars being sighted
% observation_alts: The altitudes of the stars being sighted
function [ position, circle_normals ] = sight_reduction(
  position, courses, distances, observation_GPs, observation_alts)

  num_observations = columns(observation_alts);
  assert(size(position)         == [ 3, 1 ]);
  assert(size(courses)          == [ 1, num_observations - 1 ]);
  assert(size(distances)        == [ 1, num_observations - 1 ]);
  assert(size(observation_GPs)  == [ 3, num_observations ]);
  assert(size(observation_alts) == [ 1, num_observations ]);

  circle_normals = [];

  for i = 1 : num_observations - 1
    printf(
      "\nObservation %d: Ho: %s GP: %s\n",
      i, dm_str(observation_alts(:, i)), vector_str(observation_GPs(:, i)));

    circle_normals(:, end + 1) = observation_GPs(:, i);
    position = position_fix(position, circle_normals, observation_alts(:, 1:i));

    printf("\nMovement step:\n");

    % Move along a rhumb line.
    new_position = move_constant_bearing(position, courses(i), distances(i));

    % Move the circles of equal altitude along with the observer.

    [ great_circle_azimuth, great_circle_distance ] = ...
      azimuth_distance(position, new_position);

    rot = azimuth_rotation(position, great_circle_azimuth, great_circle_distance);

    for j = 1 : columns(circle_normals)
      circle_normals(:, j) = rot * circle_normals(:, j);
    endfor

    print_new_position(position, new_position);
    position = new_position;
  endfor

  printf(
    "\nObservation %d: Ho: %s GP: %s\n",
    num_observations,
    dm_str(observation_alts(:, num_observations)),
    vector_str(observation_GPs(:, num_observations)));

  circle_normals(:, end + 1) = observation_GPs(:, num_observations);
  position = position_fix(position, circle_normals, observation_alts);
endfunction
