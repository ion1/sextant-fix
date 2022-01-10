function observed_altitude = corrected_altitude(sextant_altitude, eye_height_ft)
  apparent_altitude = sextant_altitude + dip_ft(eye_height_ft);
  observed_altitude = apparent_altitude + refraction(apparent_altitude);
endfunction
