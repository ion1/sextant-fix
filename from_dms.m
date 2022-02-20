function angle = from_dms(degrees, minutes, seconds)
  angle = deg2rad(degrees + minutes / 60 + seconds / 3600);
endfunction
