# ps: Points on the plane
# ns: Plane normals
# p: A point on the intersection
# v: A vector parallel with the intersection given only 2 planes
function [p, v] = plane_intersection(ps, ns)
  num_planes = columns(ps);
  assert(size(ps) == [ 3, num_planes ]);
  assert(size(ns) == [ 3, num_planes ]);

  ns = ensure_normalized(ns);

  # (p − p1) · n1 = 0
  # (p − p2) · n2 = 0

  # n1x px + n1y py + n1z pz − (n1x p1x + n1y p1y + n1z p1z) = 0
  # n2x px + n2y py + n2z pz − (n2x p2x + n2y p2y + n2z p2z) = 0

  # [ n1x n1y n1z ] [ px ] = [ n1x p1x + n1y p1y + n1z p1z ]
  # [ n2x n2y n2z ] [ py ] = [ n2x p2x + n2y p2y + n2z p2z ]
  #                 [ pz ]

  A = ns.';
  b = dot(ns, ps, 1).';

  # If only two planes were given, there are two equations and three unknowns.
  # A particular solution (p) is one point on the line. The null space of the
  # matrix is a vector (v) such that every p + λ v is a point on the line.
  p = A \ b;
  v = null(A);

  if (columns(v) > 1)
    error("Failed to solve");
  endif

  v = ensure_normalized(v);
endfunction
