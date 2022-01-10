# Move the vector toward the given azimuth on the surface of a sphere.
function rotated_vector = azimuth_rotate(location, azimuth, distance, vector = location)
  assert(size(vector) == [ 3, 1 ]);

  axis = azimuth_rotation_axis(location, azimuth);
  q_rot = rot2q(axis, distance);
  q = q_rot * quaternion(vector(1), vector(2), vector(3)) * conj(q_rot);

  rotated_vector = [ q.x; q.y; q.z ];
endfunction
