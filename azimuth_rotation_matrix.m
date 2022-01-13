% Matrix M such that M * axis = [ 0; c cos(a); c sin(a) ] where "axis" is an
% axis of rotation which moves the location toward an azimuth along a great
% circle, "a" is the negative azimuth angle and "c" is some non-negative
% coefficient.
function M = azimuth_rotation_matrix(location)
  assert(size(location) == [ 3, 1 ]);
  location = ensure_normalized(location);

  px = location(1);
  py = location(2);
  pz = location(3);

  % p: The location
  % n = p × north: Normal of the 0-p-north plane
  % r: Normal of the rotated plane
  % c = |n| |r|: Neither normal has to be a unit vector

  % (1) p · r = 0
  % (2) n · r = |n| |r| cos(a) = c cos(a)
  % (3) (n × r) · p = |n| |r| sin(a) = c sin(a)

  %     n = p × north = p × [ 0; 0; 1 ] = [ py; −px; 0 ]
  % (2) n · r = py rx − px ry

  %     n × r = [ −px rz; −py rz; px rx + py ry ]
  % (3) (n × r) · p = px pz rx + py pz ry − (px^2 + py^2) rz

  % (1) px rx + py ry + pz rz = 0
  % (2) py rx − px ry = c cos(a)
  % (3) px pz rx + py pz ry − (px^2 + py^2) rz = c sin(a)

  M = [
    px,       py,       pz            % (1)
    py,      -px,       0             % (2)
    px * pz,  py * pz, -(px^2 + py^2) % (3)
  ];
endfunction
