# position: A new position estimate
function [new_position] = sight_reduction_step(position, star_GP, observed_alt)
  [ predicted_az, predicted_alt ] = predict_star(position, star_GP);
  alt_diff = observed_alt - predicted_alt;

  # If the observed altitude is higher, we are closer to the star than we
  # thought. In that case, move the position toward the star's GP.
  rot = azimuth_rotation(position, predicted_az, alt_diff);
  new_position = azimuth_rotate(rot, position);
endfunction
