% pos_est: The prior estimate of the position
% GPs: The geographical positions of the stars on a unit sphere
% alts: The observed altitudes of the stars
function pos = position_fix(pos_est, GPs, alts)
  num_observations = columns(GPs);
  assert(size(pos_est) == [ 3, 1 ]);
  assert(size(GPs)     == [ 3, num_observations ]);
  assert(size(alts)    == [ 1, num_observations ]);

  printf("\nPosition fix:\n");

  GPs = ensure_normalized(GPs);

  % A point on the plane whose intersection with the sphere is the circle of
  % equal altitude.
  ps = sin(alts) .* GPs;

  if (num_observations == 1)
    printf("1 observation; moving to the circle of equal altitude\n");

    % Predict the azimuth and altitude of a star given an observer location and
    % the star's GP.
    predicted_az  = azimuth(pos_est, GPs(:, 1));
    predicted_alt = predicted_altitude(pos_est, GPs(:, 1));
    observed_alt  = alts(1);

    alt_corr = observed_alt - predicted_alt;

    printf(
      "Z: %s Hc: %s Ho: %s corr: %s\n",
      dm_str(predicted_az), dm_str(predicted_alt), dm_str(observed_alt),
      dm_str(alt_corr, " toward", " away"));

    % If the observed altitude is higher, we are closer to the star than we
    % thought. In that case, move the position towards the star's GP.
    rot = azimuth_rotation(pos_est, predicted_az, alt_corr);
    pos = rot * pos_est;

    if (false)
      % Verify the logic above; the new Hc should equal Ho.
      new_distance = distance(pos, GPs(:, 1));
      assert(abs((0.5 * pi - new_distance) - observed_alt) < 1e-12);
    endif

  elseif (num_observations > 1)
    printf(
      "%d observations; intersection of circles of equal altitude\n",
      num_observations);

    [ point, line_v ] = plane_intersection(ps, GPs);

    if (columns(line_v) == 1)
      % The solution is a line; intersect it with the sphere.

      pos_candidates = sphere_line_intersection(point, line_v);

      % Choose the candidate that is closest to the prior estimate.

      for i = 1:columns(pos_candidates)
        printf("Candidate %d: %s\n", i, vector_str(pos_candidates(:, i)));
      endfor

      [ ~, best_candidate_ix ] = min(norm(pos_candidates .- pos_est, "cols"));

      printf("Choosing candidate %d\n", best_candidate_ix);
      pos = pos_candidates(:, best_candidate_ix);

    else
      % The solution is a point, move it onto the sphere.

      len = norm(point);
      % Distance from the surface of the sphere.
      printf("Intersection error: %f\n", len - 1);
      pos = point ./ len;
    endif

  else
    error("No observations given");
  endif

  print_new_position(pos_est, pos);
endfunction
