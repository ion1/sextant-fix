function correction_angle = dip_ft(eye_height_ft)
  # https://thenauticalalmanac.com/TNARegular/2022_Nautical_Almanac.pdf page 9
  correction_angle = -from_dm(0, 0.97 * sqrt(eye_height_ft));
endfunction
