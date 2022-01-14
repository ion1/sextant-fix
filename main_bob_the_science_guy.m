clear all;

% https://youtu.be/UsekW824wJA
% The Sextant - Noon Sight
% Bob the Science Guy

% 2021-09-18 17:33 UTC

% https://thenauticalalmanac.com/TNARegular/2021_Nautical_Almanac.pdf

sun_GHAs = [
  from_dm(76, 30.3) + from_dm(8, 15.0) % The beginning of the minute
  from_dm(76, 30.3) + from_dm(8, 30.0) % The end of the minute
].';
sun_dec = from_dm(1, 35.5) - from_dm(0, 1.0) * 33/60;

sun_GPs = zeros(3, 0);
for i = 1 : columns(sun_GHAs)
  sun_GPs(:, end + 1) = coord_to_vector(sun_dec, -sun_GHAs(i));
endfor

err = from_dm(0, 7.2);

Hos = [
  from_dm(47, 53.2) + err
  from_dm(47, 52.7) - err
].';

distances = pi / 2 - Hos;

for i = 1 : columns(sun_GPs)
  sun_GP = sun_GPs(:, i);
  printf("Sun GP: %s\n", vector_str(sun_GP));

  for j = 1 : columns(distances)
    distance = distances(j);
    printf("  Distance: %s\n", dm_str(distance));

    rot = azimuth_rotation(sun_GP, 0, distance);
    pos = rot * sun_GP;

    printf("    Position: %s\n", vector_str(pos));
  endfor
endfor
