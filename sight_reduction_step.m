# position: A new position estimate
function [new_position] = sight_reduction_step(position, star_GP, observed_alt)
  [ predicted_alt, predicted_az ] = predict_star(position, star_GP);
  alt_diff = observed_alt - predicted_alt;

  # If the observed altitude is higher, we are closer to the star than we
  # thought. In that case, move the position toward the star's GP.
  new_position = azimuth_rotate(position, predicted_az, alt_diff);
endfunction
