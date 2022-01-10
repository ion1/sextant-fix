function [ latitude, longitude ] = vector_to_coord(v)
  assert(size(v) == [ 3, 1 ]);
  v = ensure_normalized(v);

  latitude  = asin(v(3));
  longitude = atan2(v(2), v(1));
endfunction
