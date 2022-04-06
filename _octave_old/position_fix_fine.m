% pos_est: The prior estimate of the position
% GPs: The geographical positions of the stars on a unit sphere
% alts: The observed altitudes of the stars
function pos = position_fix_fine(pos_est, GPs, alts)
  num_observations = columns(GPs);
  assert(size(pos_est) == [ 3, 1 ]);
  assert(size(GPs)     == [ 3, num_observations ]);
  assert(size(alts)    == [ 1, num_observations ]);

  printf("\nPosition fix (local, fine):\n");

  dists = pi / 2 - alts;

  pos = pos_est;

  if (num_observations == 1)
    printf("1 observation; moving to the circle of equal altitude\n");
  elseif (num_observations > 1)
    printf(
      "%d observations; intersection of circles of equal altitude\n",
      num_observations);
  else
    error("No observations given");
  endif

  correction = 0;
  do
    print_errors(pos, GPs, dists);

    [tbn, GPs_ae] = to_azimuthal_equidistant(pos, GPs);

    % Unit vectors from the GPs to the position (0 in the AE projection).
    vs = -GPs_ae;
    vs ./= norm(vs, "columns");

    if (num_observations == 1)
      % Move radially toward or away from the GP to correct the distance.
      new_pos_ae = GPs_ae(:, 1) + vs(:, 1) * dists(1);
    else
      % Find the point closest to all of the tangent planes of the circles at
      % the respective points closest to pos. This is an iterative approximation
      % of finding the point closest to all of the circles if pos is already
      % close to the correct position.

      % (pos - GP1) . v1 = dist1
      % (pos - GP2) . v2 = dist2

      % v1 . p = dist1 + v1 . GP1
      % v2 . p = dist2 + v2 . GP2

      % [ v1x v1y ] [ px ] = [ dist1 + v1 . GP1 ]
      % [ v2x v2y ] [ py ]   [ dist2 + v2 . GP2 ]

      A = vs.';
      b = (dists + dot(vs, GPs_ae, 1)).';

      new_pos_ae = A \ b;
    endif

    new_pos = from_azimuthal_equidistant(tbn, new_pos_ae);
    correction = distance(pos, new_pos);

    printf("Correction: %s\n", nautical_miles_str(correction));

    pos = new_pos;
  until (correction < from_dm(0, 0.01))

  print_errors(pos, GPs, dists);

  print_new_position(pos_est, pos);
endfunction

function print_errors(pos, GPs, dists)
  printf("  Errors:");
  for i = 1:columns(GPs)
    printf(" %s", nautical_miles_str(distance(GPs(:, i), pos) - dists(i)));
  endfor
  printf("\n");
endfunction
