% pos_est: The prior estimate of the position
% GPs: The geographical positions of the stars on a unit sphere
% alts: The observed altitudes of the stars
function pos = position_fix(pos_est, GPs, alts)
  pos = position_fix_rough(pos_est, GPs, alts);
  pos = position_fix_fine(pos, GPs, alts);
endfunction
