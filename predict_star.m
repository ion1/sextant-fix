# Predict the azimuth and altitude of a star given an observer location and the
# star's GP.
function [ azimuth, altitude ] = predict_star(location, star_GP)
  [ azimuth, distance ] = azimuth_distance(location, star_GP);
  altitude = 0.5 * pi - distance;
endfunction
