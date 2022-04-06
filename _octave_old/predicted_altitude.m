% The predicted altitude angle of a star at GP when viewed from pos.
% pos: The position of the observer
% GP: The geographical position of the star
function alt = predicted_altitude(pos, GP)
  alt = pi * 0.5 - distance(pos, GP);
endfunction
