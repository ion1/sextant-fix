% An axis of rotation which results in movement toward the given azimuth on the
% given location on the surface of a sphere.
function axis = azimuth_rotation_axis(location, azimuth)
  M = azimuth_rotation_matrix(location);
  % An azimuth angle increases clockwise.
  b = [ 0; cos(-azimuth); sin(-azimuth) ];

  axis = M \ b;
  axis = axis ./ norm(axis);
endfunction
