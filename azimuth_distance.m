# The distance (in radians) and the azimuth from v1 to v2 on a sphere.
function [ azimuth, distance ] = azimuth_distance(v1, v2)
  assert(size(v1) == [ 3, 1 ]);
  assert(size(v2) == [ 3, 1 ]);
  v1 = ensure_normalized(v1);
  v2 = ensure_normalized(v2);

  v1_x_v2 = cross(v1, v2);

  # Distance

  # v1 · v2 = |v1| |v2| cos(angle) = cos(angle)
  # v1 × v2 = |v1| |v2| vn sin(angle) = vn sin(angle)
  # |v1 × v2| = |v1| |v2| |vn| sin(angle) = sin(angle)

  # tan(angle) = sin(angle)/cos(angle). Using atan probably has better numerical
  # behavior than just using acos on the dot product when the angle is small
  # and the cosine has a tiny offset from 1 rather than from 0.

  sin_distance = norm(v1_x_v2);
  cos_distance = dot(v1, v2);
  distance = atan2(sin_distance, cos_distance);

  # Azimuth

  M = azimuth_rotation_matrix(v1);
  # v1 × v2 is the axis of rotation.
  b = M * v1_x_v2;
  assert(abs(b(1)) < 1e-12);
  angle = atan2(b(3), b(2));

  # An azimuth angle increases clockwise.
  azimuth = mod(-angle, 2 * pi);
endfunction
