function print_new_position(old_position, new_position, label = "Position:")
  printf("%s %s\n", label, vector_str(new_position));
  printf(
    "  Bearing: %s, distance: %s\n",
    dm_str(azimuth(old_position, new_position)),
    dm_str(distance(old_position, new_position)));
endfunction
