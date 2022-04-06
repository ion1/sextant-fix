function time = from_hms(hours, minutes, seconds)
  time = hours + minutes / 60 + seconds / 3600;
endfunction
