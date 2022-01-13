# pos_est: The prior estimate of the position
# GPs: The geographical positions of the stars on a unit sphere
# alts: The observed altitudes of the stars
function pos = position_fix(pos_est, GPs, alts)
  num_observations = columns(GPs);
  assert(size(pos_est) == [ 3, 1 ]);
  assert(size(GPs)     == [ 3, num_observations ]);
  assert(size(alts)    == [ 1, num_observations ]);

  printf("\nPosition fix:\n");

  GPs = ensure_normalized(GPs);

  # A point on the plane whose intersection with the sphere is the circle of
  # equal altitude.
  ps = sin(alts) .* GPs;

  if (num_observations == 1)
    printf("1 observation; moving to the circle of equal altitude\n");

    # Predict the azimuth and altitude of a star given an observer location and
    # the star's GP.
    [ predicted_az, distance ] = azimuth_distance(pos_est, GPs(:, 1));
    predicted_alt = 0.5 * pi - distance;
    observed_alt  = alts(1);

    alt_diff = predicted_alt - observed_alt;

    printf(
      "Hc: %s Ho: %s diff: %s\n",
      dm_str(predicted_alt), dm_str(observed_alt),
      dm_str(alt_diff, " toward", " away"));

    # If the predicted altitude is higher, we are further from the star than we
    # thought. In that case, move the position toward the star's GP.
    rot = azimuth_rotation(pos_est, predicted_az, alt_diff);
    pos = rot * pos_est;

  elseif (num_observations > 1)
    printf(
      "%d observations; intersection of circles of equal altitude\n",
      num_observations);

    [ point, line_v ] = plane_intersection(ps, GPs);

    if (columns(line_v) == 1)
      # The solution is a line; intersect it with the sphere.

      pos_candidates = sphere_line_intersection(point, line_v);

      # Choose the candidate that is closest to the prior estimate.

      for i = 1:columns(pos_candidates)
        printf("Candidate %d: %s\n", i, vector_str(pos_candidates(:, i)));
      endfor

      [ ~, best_candidate_ix ] = min(norm(pos_candidates .- pos_est, "cols"));

      printf("Choosing candidate %d\n", best_candidate_ix);
      pos = pos_candidates(:, best_candidate_ix);

    else
      # The solution is a point, move it onto the sphere.

      len = norm(point);
      # Distance from the surface of the sphere.
      printf("Intersection error: %f\n", len - 1);
      pos = point ./ len;
    endif

  else
    error("No observations given");
  endif

  print_new_position(pos_est, pos);
endfunction
