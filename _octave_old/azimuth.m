% The azimuth from v1 to v2 on a sphere.
function az = azimuth(v1, v2)
  assert(size(v1) == [ 3, 1 ]);
  assert(size(v2) == [ 3, 1 ]);

  M = azimuth_rotation_matrix(v1);
  % v1 × v2 is the axis of rotation.
  b = M * cross(v1, v2);
  assert(abs(b(1)) < 1e-12);
  angle = atan2(b(3), b(2));

  % An azimuth angle increases clockwise.
  az = mod(-angle, 2 * pi);
endfunction
