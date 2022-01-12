# Move a vector on the surface of a sphere according to a rhumb line.
# vector_initial: The initial position
# bearing: The constant bearing
# distance: The total distance along the rhumb line
function vector = move_constant_bearing(vector_initial, bearing, distance)
  assert(size(vector_initial) == [ 3, 1 ]);
  ensure_normalized(vector_initial);

  [ lat_i, lon_i ] = vector_to_coord(vector_initial);

  # https://www.movable-type.co.uk/scripts/latlong.html#rhumb-destination

  lat = lat_i + cos(-bearing) * distance;
  if (abs(lat) > pi / 2)
    error(
      "Tried to go past the pole, v: %s, bearing: %s, distance: %s",
      vec2mat(vector_initial), dm_str(bearing), dm_str(distance));
  endif

  mercator_lat_diff = log(tan(pi / 4 + lat / 2) / tan(pi / 4 + lat_i / 2));
  if (abs(mercator_lat_diff) < 1e-12)
    lat_ratio = cos(lat_i);
  else
    lat_ratio = (lat - lat_i) / mercator_lat_diff;
  endif

  lon = lon_i - sin(-bearing) * distance / lat_ratio;

  vector = coord_to_vector(lat, lon);
endfunction
