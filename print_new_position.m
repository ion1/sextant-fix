function print_new_position(old_position, new_position, label = "Position:")
  [ azimuth, distance ] = azimuth_distance(old_position, new_position);

  printf("%s %s\n", label, vector_str(new_position));
  printf("  Bearing: %s, distance: %s\n", dm_str(azimuth), dm_str(distance));
endfunction
