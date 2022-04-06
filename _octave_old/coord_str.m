function str = coord_str(lat, lon)
  query = sprintf("%s%%2C%s", latitude_str_url(lat), longitude_str_url(lon));
  url = sprintf("https://www.google.com/maps/search/?api=1&query=%s", query);

  str = sprintf("%s %s %s", latitude_str(lat), longitude_str(lon), url);
endfunction

function str = latitude_str(angle)
  str = dm_str(angle, "N", "S");
endfunction

function str = latitude_str_url(angle)
  str = dm_str_url(angle, "N", "S");
endfunction

function str = longitude_str(angle)
  normalized_angle = normalize_longitude(angle);
  str = dm_str(normalized_angle, "E", "W");
endfunction

function str = longitude_str_url(angle)
  normalized_angle = normalize_longitude(angle);
  str = dm_str_url(normalized_angle, "E", "W");
endfunction

function normalized_angle = normalize_longitude(angle)
  normalized_angle = mod(angle + pi, 2 * pi) - pi;
endfunction
