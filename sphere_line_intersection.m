function intersections = sphere_line_intersection(p, v, radius = 1)
  v = ensure_normalized(v);

  # The line:
  # x = px + λ vx
  # y = py + λ vy
  # z = pz + λ vz

  # The sphere:
  # x^2 + y^2 + z^2 = radius^2

  # (px + λ vx)^2 + (py + λ vy)^2 + (pz + λ vz)^2 = radius^2
  #
  # px^2 + py^2 + pz^2 + 2 λ (px vx + py vy + pz vz) + λ^2 (vx^2 + vy^2 + vz^2) = radius^2
  #
  # v is a unit vector, therefore vx^2 + vy^2 + vz^2 = 1
  #
  # px^2 + py^2 + pz^2 + 2 λ (px vx + py vy + pz vz) + λ^2 = radius^2
  #
  # λ^2 + (2 (px vx + py vy + pz vz)) λ + (px^2 + py^2 + pz^2 − radius^2) = 0

  lambda = roots([ 1, 2 * dot(p, v), dot(p, p) - radius^2 ]);

  # The solutions: p + λ v
  intersections = p + lambda.' .* v;
  assert(size(intersections) == [ 3, 2 ]);
endfunction
