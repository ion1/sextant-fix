function print_new_position(old_position, new_position, label = "Position:")
  printf("%s %s\n", label, vector_str(new_position));
  if (max(abs(old_position)) > 1e-6)
    printf(
      "  Bearing: %s, distance: %s\n",
      dm_str(azimuth(old_position, new_position)),
      nautical_miles_str(distance(old_position, new_position)));
  endif
endfunction
