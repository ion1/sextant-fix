# gp1, gp2: The star's GP on a unit sphere
# alt1, alt2: The observed altitude of the star
function vectors = position_fix(GP1, alt1, GP2, alt2)
  GP1 = ensure_normalized(GP1);
  GP2 = ensure_normalized(GP2);

  # A point on the plane whose intersection with the sphere is the circle of
  # equal altitude
  p1 = sin(alt1) .* GP1;
  p2 = sin(alt2) .* GP2;

  [ line_p, line_v ] = plane_intersection(p1, GP1, p2, GP2);

  vectors = sphere_line_intersection(line_p, line_v);
endfunction
