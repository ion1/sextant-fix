function str = dm_str_base(angle, pos_suffix = "", neg_suffix = "−", mode = "normal")
  angle_deg = round(rad2deg(angle) * 600) / 600;
  degrees = fix(angle_deg);
  minutes = (angle_deg - degrees) * 60;

  if (angle < 0)
    suffix = neg_suffix;
  else
    suffix = pos_suffix;
  endif

  if (strcmp(mode, "normal"))
    format = "%3d°%04.1f′%s";
  elseif (strcmp(mode, "url"))
    format = "%d%%C2%%B0%04.1f'%s";
  else
    error("Unrecognized mode: %s", mode);
  endif

  str = sprintf(format, abs(degrees), abs(minutes), suffix);
endfunction
