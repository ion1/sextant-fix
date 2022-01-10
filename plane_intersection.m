# p1, p2: A point on the plane
# n1, n2: Plane normal
# p: A point on the intersection
# v: A vector parallel with the intersection
function [p, v] = plane_intersection(p1, n1, p2, n2)
  n1 = ensure_normalized(n1);
  n2 = ensure_normalized(n2);

  # (p − p1) · n1 = 0
  # (p − p2) · n2 = 0

  # n1x px + n1y py + n1z pz − (n1x p1x + n1y p1y + n1z p1z) = 0
  # n2x px + n2y py + n2z pz − (n2x p2x + n2y p2y + n2z p2z) = 0

  A = [ n1, n2 ].';
  b = [ dot(n1, p1); dot(n2, p2) ];

  # There are two equations and three unknowns. A particular solution (p) is one
  # point on the line. The null space of the matrix is a vector (v) such that
  # every p + λ v is a point on the line.
  p = A \ b;
  v = null(A);
  assert(size(v) == [ 3, 1 ]);
  v = ensure_normalized(v);
endfunction
