% The distance (in radians) from v1 to v2 on a sphere.
function d = distance(v1, v2)
  assert(size(v1) == [ 3, 1 ]);
  assert(size(v2) == [ 3, 1 ]);
  v1 = ensure_normalized(v1);
  v2 = ensure_normalized(v2);

  % v1 · v2 = |v1| |v2| cos(angle) = cos(angle)
  % v1 × v2 = |v1| |v2| vn sin(angle) = vn sin(angle)
  % |v1 × v2| = |v1| |v2| |vn| sin(angle) = sin(angle)

  % tan(angle) = sin(angle)/cos(angle). Using atan probably has better numerical
  % behavior than just using acos on the dot product when the angle is small
  % and the cosine has a tiny offset from 1 rather than from 0.

  sin_distance = norm(cross(v1, v2));
  cos_distance = dot(v1, v2);
  d = atan2(sin_distance, cos_distance);
endfunction
