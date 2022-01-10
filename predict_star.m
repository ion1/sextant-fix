# Predict the altitude and azimuth of a star given an observer location and the
# star's GP.
function [altitude, azimuth] = predict_star(location, star_GP)
  [distance, azimuth] = distance_azimuth(location, star_GP);
  altitude = 0.5 * pi - distance;
endfunction
