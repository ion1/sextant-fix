function vector = coord_to_vector(latitude, longitude)
  cos_lat = cos(latitude);
  vector = [
    cos(longitude) * cos_lat
    sin(longitude) * cos_lat
    sin(latitude)
  ];
endfunction
