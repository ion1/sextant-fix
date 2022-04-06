% Construct a matrix corresponding to moving a vector toward the given
% azimuth along a great circle.
% M: A matrix representing the rotation corresponding to the movement
% location: The vector at which the azimuth is evaluated
% distance: The distance on the surface of the the sphere in radians
function M = azimuth_rotation(location, azimuth, distance)
  axis = azimuth_rotation_axis(location, azimuth);

  % https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula

  % v_rot = v cos(θ) + (axis × v) sin(θ) + axis (axis · v) (1 − cos(θ))

  c = cos(distance);
  s = sin(distance);

  M = eye(3) * c + skew(axis) * s + axis * axis.' * (1 - c);
endfunction

function M = skew(v)
  M = [
    0     -v(3)   v(2)
    v(3)   0     -v(1)
   -v(2)   v(1)   0
  ];
endfunction
