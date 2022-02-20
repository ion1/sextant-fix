% Given a center point and other points on the unit sphere, return an azimuthal
% equidistant projection of the points.
% p: A center point on the unit sphere
% q: Points on the unit sphere
% q_ae: An azimuthal equidistant projection of the points q
% tbn: A matrix to reorient the 2D q_ae to the 3D projection plane
function [tbn, q_ae] = to_azimuthal_equidistant(p, q)
  assert(size(p) == [ 3, 1 ]);
  assert(rows(q) == 3);

  p = ensure_normalized(p);
  q = ensure_normalized(q);

  % Given p and q on the unit sphere, project a line from the antipodal point of
  % p to q onto the tangent plane at p.

  % Point on the line:
  % l(λ) = −p + λ (q − (−p)) = λ (q + p) − p

  % The intersection:
  % (l(λ) − p) · n = 0
  % n = p
  % (λ (q + p) − p − p) · n = 0
  % (λ (q + p) − 2 p) · n = 0
  % λ ((q + p) · n) − 2 p · n = 0
  % λ ((q + p) · n) = 2 p · n
  % λ = 2 p · n / ((q + p) · n)

  n = p;

  denom = dot(q + p, repmat(n, 1, columns(q)), 1);
  assert(
    abs(denom) >= 1e-12,
    "a q is on the antipodal point of p");

  lambda = 2 * dot(p, n) ./ denom;
  q_stereographic = lambda .* (q + p) - p;

  v = q_stereographic - p;
  v_len = norm(v, "columns");

  q_azi_equi = ifelse(
    repmat(abs(v_len) < 1e-12, 3, 1),
    % Select p for values that are on p.
    repmat(p, 1, columns(v)),
    % Scale the length to achieve an azimuthal equidistant projection.
    p + v .* 2 .* atan(v_len ./ 2) ./ v_len);

  if (false)
    for i = 1:columns(q)
      pq_sphere_dist = distance(p, q(:, i));
      pq_proj_dist = norm(q_azi_equi(:, i) - p);
      assert(abs(pq_proj_dist - pq_sphere_dist) < 1e6 * eps(max(pq_proj_dist, pq_sphere_dist)));
    endfor
  endif

  % Pick arbitrary axes for the 2D orientation of the projection plane.
  right = cross([ 0; 0; 1 ], n);
  right_len = norm(right);
  if (abs(right_len) < 1e-6)
    right = cross([ -1; 0; 0 ], n);
    right_len = norm(right);
  endif
  right ./= right_len;
  up = cross(n, right);

  % Tangent, bitangent, normal vector for the projection plane.
  tbn = [ right up n ];

  q_ae = tbn.' * q_azi_equi;
  assert(abs(q_ae(3, :)) - 1 < 1e-12, "q_ae is not on the projection plane");

  q_ae = q_ae(1:2, :);
endfunction
