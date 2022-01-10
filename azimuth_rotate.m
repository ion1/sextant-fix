# Rotate a vector using a quaternion.
# q_rot: A quaternion representing the rotation
# v: The vector to be rotated
function rotated_vector = azimuth_rotate(q_rot, v)
  assert(size(v) == [ 3, 1 ]);

  q = q_rot * quaternion(v(1), v(2), v(3)) * conj(q_rot);

  rotated_vector = [ q.x; q.y; q.z ];
endfunction
