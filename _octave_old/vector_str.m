function str = vector_str(v)
  assert(size(v) == [ 3, 1 ]);

  [ lat, lon ] = vector_to_coord(v);
  str = coord_str(lat, lon);
endfunction
