function correction_angle = refraction(apparent_altitude)
  # https://thenauticalalmanac.com/TNARegular/2022_Nautical_Almanac.pdf page 8
  # https://ur.booksc.eu/book/38210957/71b18e
  # The Calculation of Astronomical Refraction in Marine Navigation
  # Bennet, G. G., 1982
  Ha = rad2deg(apparent_altitude);
  correction_angle = -from_dm(0, cotd(Ha + 7.31 / (Ha + 4.4)));
endfunction
