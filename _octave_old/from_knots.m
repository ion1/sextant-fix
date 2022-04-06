% speed: Speed in radians/hour
% speed_knots: Speed in knots
function speed = from_knots(speed_knots)
  km_hr_in_knots = 1.852;
  earth_radius_km = 6371;
  speed = speed_knots * km_hr_in_knots / earth_radius_km;
endfunction
