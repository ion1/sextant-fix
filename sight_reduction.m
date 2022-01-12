# new_position: The final position of the observer
# circle_normals: The normals of the circles whose intersection is the position
# position: The initial position of the observer
# courses: The course between each observation
# distances: The distance travelled between each observation
# observation_GPs: The geographical points of the stars being sighted
# observation_alts: The altitudes of the stars being sighted
function [new_position, circle_normals] = sight_reduction(
  position, courses, distances, observation_GPs, observation_alts)

  num_observations = columns(observation_alts);
  assert(size(position)         == [ 3, 1 ]);
  assert(size(courses)          == [ 1, num_observations - 1 ]);
  assert(size(distances)        == [ 1, num_observations - 1 ]);
  assert(size(observation_GPs)  == [ 3, num_observations ]);
  assert(size(observation_alts) == [ 1, num_observations ]);

  circle_normals = [];

  for i = 1 : num_observations - 1
    course          = courses(i);
    distance        = distances(i);
    observation_GP  = observation_GPs(:, i);
    observation_alt = observation_alts(i);

    printf("\nSight reduction step\n");
    new_position = sight_reduction_step(
      position, observation_GP, observation_alt);
    circle_normals(:, end + 1) = observation_GP;

    print_new_position(position, new_position);
    position = new_position;

    printf("\nMovement step\n");

    # Move along a rhumb line.
    new_position = move_constant_bearing(position, course, distance);

    # Move the circles of equal altitude along with the observer.
    [ great_circle_azimuth, great_circle_distance ] = ...
      azimuth_distance(position, new_position);

    rot = azimuth_rotation(position, great_circle_azimuth, great_circle_distance);

    for j = 1 : columns(circle_normals)
      circle_normals(:, j) = azimuth_rotate(rot, circle_normals(:, j));
    endfor

    print_new_position(position, new_position);
    position = new_position;
  endfor

  printf("\nSight reduction step\n");
  new_position = sight_reduction_step(
    position, observation_GPs(:, end), observation_alts(end));
  circle_normals(:, end + 1) = observation_GPs(:, end);

  print_new_position(position, new_position);
  position = new_position;
endfunction

function print_new_position(old_position, new_position)
  [ azimuth, distance ] = azimuth_distance(old_position, new_position);

  printf("Position: %s\n", vector_str(new_position));
  printf("  Bearing: %s, distance: %s\n", dm_str(azimuth), dm_str(distance));
endfunction
