% Given points on an azimuthal equidistant projection, return the corresponding
% points on the unit sphere.
% tbn: A matrix to reorient the 2D q_ae to the 3D projection plane
% q_ae: An azimuthal equidistant projection of the points q
% q: Points on the unit sphere
function q = from_azimuthal_equidistant(tbn, q_ae)
  assert(size(tbn) == [ 3, 3 ]);
  assert(rows(q_ae) == 2);

  p = tbn(:, 3);
  q_azi_equi = tbn * [ q_ae; ones(1, columns(q_ae)) ];

  v = q_azi_equi - p;
  v_len = norm(v, "columns");

  q_stereographic = ifelse(
    repmat(abs(v_len) < 1e-12, 3, 1),
    % Select p for values that are on p.
    repmat(p, 1, columns(v)),
    % Scale the length to achieve a stereographic projection.
    p + v .* 2 .* tan(v_len ./ 2) ./ v_len);

  % Project a line from a point on the tangent plane to the antipodal point of p
  % onto the unit sphere.

  % Point on the line:
  % l(λ) = −p + λ (q − (−p)) = λ (q + p) − p

  % The intersection:
  % l(λ) · l(λ) = 1
  % (λ (q + p) − p) · (λ (q + p) − p) = 1
  % λ^2 ((q + p) · (q + p))
  %   − λ (2 (q + p) · p)
  %   + (p · p − 1)
  %   = 0

  % p is a unit vector;
  %   (p · p − 1) = 0.
  % q is on the plane whose normal is p which is a unit vector;
  %   (q + p) · p = 1 + 1 = 2.

  % λ^2 ((q + p) · (q + p))
  %   − λ 4
  %   = 0

  % Quadratic formula
  % a = (q + p) · (q + p)
  % b = −4
  % λ = −b ± sqrt(b^2) / (2 a)

  % Only use the positive square root term.

  % a = (q + p) · (q + p)
  % λ = 4 + sqrt(4^2) / (2 a)

  % λ = 4 / ((q + p) · (q + p))

  lambda = 4 ./ dot(q_stereographic + p, q_stereographic + p, 1);

  q = ifelse(
    repmat(abs(v_len) >= pi - 1e-6, 3, 1),
    % Select the antipodal point to p for distances at pi.
    repmat(-p, 1, columns(v)),
    lambda .* (q_stereographic + p) - p);

  q = ensure_normalized(q);
endfunction
