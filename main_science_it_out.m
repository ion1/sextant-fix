clear all;

function location_1()
  % https://youtu.be/J7XmHIjKaP4
  % Celestial Navigation Challenge
  % Science It Out

  % Location 1:
  % Alkaid – 56°07’03.3”
  % Capella – 33°42’42.5”
  % Alphard – 38°05’46.3”
  % Time: 2021-12-17 10:35:27 UTC

  printf("Location 1\n");

  alkaid_sextant_alt  = from_dms(56, 07, 03.3);
  capella_sextant_alt = from_dms(33, 42, 42.5);
  alphard_sextant_alt = from_dms(38, 05, 46.3);
  observation_time = from_hms(10, 35, 27);
  eye_height = 0;
  alkaid_observed_alt  = corrected_altitude(alkaid_sextant_alt, 0, eye_height, 0);
  capella_observed_alt = corrected_altitude(capella_sextant_alt, 0, eye_height, 0);
  alphard_observed_alt = corrected_altitude(alphard_sextant_alt, 0, eye_height, 0);

  printf("Alkaid Hs, Ho:  %s %s\n", dm_str(alkaid_sextant_alt), dm_str(alkaid_observed_alt));
  printf("Capella Hs, Ho: %s %s\n", dm_str(capella_sextant_alt), dm_str(capella_observed_alt));
  printf("Alphard Hs, Ho: %s %s\n", dm_str(alphard_sextant_alt), dm_str(alphard_observed_alt));

  % https://thenauticalalmanac.com/TNARegular/2021_Nautical_Almanac.pdf page 250
  aries_GHA_t = [
    10 from_dm(234, 16.8)
    11 from_dm(249, 19.3)
  ];
  aries_GHA = interp1(aries_GHA_t(:, 1), aries_GHA_t(:, 2), observation_time);

  alkaid_SHA  = from_dm(152, 54.3);
  alkaid_dec  = from_dm( 49, 12.1);
  capella_SHA = from_dm(280, 25.1);
  capella_dec = from_dm( 46, 01.2);
  alphard_SHA = from_dm(217, 50.0);
  alphard_dec = from_dm( -8, 45.1);

  alkaid_GHA  = aries_GHA + alkaid_SHA;
  capella_GHA = aries_GHA + capella_SHA;
  alphard_GHA = aries_GHA + alphard_SHA;

  alkaid_GP  = coord_to_vector(alkaid_dec, -alkaid_GHA);
  capella_GP = coord_to_vector(capella_dec, -capella_GHA);
  alphard_GP = coord_to_vector(alphard_dec, -alphard_GHA);

  printf("Alkaid GP:  %s\n", vector_str(alkaid_GP));
  printf("Capella GP: %s\n", vector_str(capella_GP));
  printf("Alphard GP: %s\n", vector_str(alphard_GP));

  observation_GPs  = [ alkaid_GP, capella_GP, alphard_GP ];
  observation_alts = [ alkaid_observed_alt, capella_observed_alt, alphard_observed_alt ];

  position_fix([ 0; 0; 0 ], observation_GPs, observation_alts);

  printf("\n");
endfunction

function location_2()
  % https://youtu.be/J7XmHIjKaP4
  % Celestial Navigation Challenge
  % Science It Out

  % Location 2:
  % Betelgeuse – 45°12’13.4”
  % Canopus – 42°36’17.6”
  % Achernar – 46°53’16.4”
  % Time: 2021-12-17 18:18:15 UTC

  printf("Location 2\n");

  betelgeuse_sextant_alt = from_dms(45, 12, 13.4);
  canopus_sextant_alt    = from_dms(42, 36, 17.6);
  achernar_sextant_alt   = from_dms(46, 53, 16.4);
  observation_time = from_hms(18, 18, 15);
  eye_height = 0;
  betelgeuse_observed_alt = corrected_altitude(betelgeuse_sextant_alt, 0, eye_height, 0);
  canopus_observed_alt    = corrected_altitude(canopus_sextant_alt, 0, eye_height, 0);
  achernar_observed_alt   = corrected_altitude(achernar_sextant_alt, 0, eye_height, 0);

  printf("Betelgeuse Hs, Ho: %s %s\n", dm_str(betelgeuse_sextant_alt), dm_str(betelgeuse_observed_alt));
  printf("Canopus Hs, Ho:    %s %s\n", dm_str(canopus_sextant_alt), dm_str(canopus_observed_alt));
  printf("Achernar Hs, Ho:   %s %s\n", dm_str(achernar_sextant_alt), dm_str(achernar_observed_alt));

  % https://thenauticalalmanac.com/TNARegular/2021_Nautical_Almanac.pdf page 250
  aries_GHA_t = [
    18 from_dm(354, 36.6)
    19 from_dm(360 + 9, 39.0)
  ];
  aries_GHA = interp1(aries_GHA_t(:, 1), aries_GHA_t(:, 2), observation_time);

  betelgeuse_SHA = from_dm(270, 54.5);
  betelgeuse_dec = from_dm(  7, 24.6);
  canopus_SHA    = from_dm(263, 53.0);
  canopus_dec    = from_dm(-52, 42.4);
  achernar_SHA   = from_dm(335, 21.8);
  achernar_dec   = from_dm(-57, 07.9);

  betelgeuse_GHA = aries_GHA + betelgeuse_SHA;
  canopus_GHA    = aries_GHA + canopus_SHA;
  achernar_GHA   = aries_GHA + achernar_SHA;

  betelgeuse_GP  = coord_to_vector(betelgeuse_dec, -betelgeuse_GHA);
  canopus_GP     = coord_to_vector(canopus_dec, -canopus_GHA);
  achernar_GP    = coord_to_vector(achernar_dec, -achernar_GHA);

  printf("Betelgeuse GP: %s\n", vector_str(betelgeuse_GP));
  printf("Canopus GP:    %s\n", vector_str(canopus_GP));
  printf("Achernar GP:   %s\n", vector_str(achernar_GP));

  observation_GPs  = [ betelgeuse_GP, canopus_GP, achernar_GP ];
  observation_alts = [ betelgeuse_observed_alt, canopus_observed_alt, achernar_observed_alt ];

  position_fix([ 0; 0; 0 ], observation_GPs, observation_alts);

  printf("\n");
endfunction

function location_3()
  % https://youtu.be/J7XmHIjKaP4
  % Celestial Navigation Challenge
  % Science It Out

  % Location 3:
  % Diphda – 47°39’43.8”
  % Hamal – 84°45’21.7”
  % Alpheratz – 66°42’57.8”
  % Time: 2021-08-12 17:18:15 UTC

  printf("Location 3\n");

  diphda_sextant_alt    = from_dms(47, 39, 43.8);
  hamal_sextant_alt     = from_dms(84, 45, 21.7);
  alpheratz_sextant_alt = from_dms(66, 42, 57.8);
  observation_time = from_hms(17, 18, 15);
  eye_height = 0;
  diphda_observed_alt    = corrected_altitude(diphda_sextant_alt, 0, eye_height, 0);
  hamal_observed_alt     = corrected_altitude(hamal_sextant_alt, 0, eye_height, 0);
  alpheratz_observed_alt = corrected_altitude(alpheratz_sextant_alt, 0, eye_height, 0);

  printf("Diphda Hs, Ho:    %s %s\n", dm_str(diphda_sextant_alt), dm_str(diphda_observed_alt));
  printf("Hamal Hs, Ho:     %s %s\n", dm_str(hamal_sextant_alt), dm_str(hamal_observed_alt));
  printf("Alpheratz Hs, Ho: %s %s\n", dm_str(alpheratz_sextant_alt), dm_str(alpheratz_observed_alt));

  % https://thenauticalalmanac.com/TNARegular/2021_Nautical_Almanac.pdf page 166
  aries_GHA_t = [
    17 from_dm(216, 21.8)
    18 from_dm(231, 24.2)
  ];
  aries_GHA = interp1(aries_GHA_t(:, 1), aries_GHA_t(:, 2), observation_time);

  diphda_SHA    = from_dm(348, 49.9);
  diphda_dec    = from_dm(-17, 52.0);
  hamal_SHA     = from_dm(327, 54.2);
  hamal_dec     = from_dm( 23, 33.7);
  alpheratz_SHA = from_dm(357, 37.4);
  alpheratz_dec = from_dm( 29, 12.5);

  diphda_GHA    = aries_GHA + diphda_SHA;
  hamal_GHA     = aries_GHA + hamal_SHA;
  alpheratz_GHA = aries_GHA + alpheratz_SHA;

  diphda_GP    = coord_to_vector(diphda_dec, -diphda_GHA);
  hamal_GP     = coord_to_vector(hamal_dec, -hamal_GHA);
  alpheratz_GP = coord_to_vector(alpheratz_dec, -alpheratz_GHA);

  printf("Diphda GP:    %s\n", vector_str(diphda_GP));
  printf("Hamal GP:     %s\n", vector_str(hamal_GP));
  printf("Alpheratz GP: %s\n", vector_str(alpheratz_GP));

  observation_GPs  = [ diphda_GP, hamal_GP, alpheratz_GP ];
  observation_alts = [ diphda_observed_alt, hamal_observed_alt, alpheratz_observed_alt ];

  position_fix([ 0; 0; 0 ], observation_GPs, observation_alts);

  printf("\n");
endfunction

function location_4()
  % https://youtu.be/Sq1V98vkfQw
  % Where am I?
  % Science It Out

  % 2022-02-09
  % Observer height: approx. 50 m

  % Sun, lower limb:
  % 14:15:56 11°25.0’
  % 17:03:41  2°08.8’
  % 17:10:05  1°45.7’
  % 17:13:30  1°26.6’
  % 17:16:20  1°14.6’

  % Sun, upper limb:
  % 17:21:30  1°16.6’
  % 17:24:25  0°58.4’

  % Jupiter:
  % 18:28:23  6°23.4’

  % Alpheratz: 19:04:54 46°08.2’
  % Hamal:     19:08:06 49°45.2’
  % Deneb:     19:10:13 34°27.2’
  % Mirach:    19:17:10 56°07.1’

  printf("Location 4\n");

  eye_height = from_meters(50);

  % https://thenauticalalmanac.com/TNARegular/2022_Nautical_Almanac.pdf pages 44, 45
  sun_LL = from_dm(0, 16.2);
  sun_UL = -sun_LL;

  sun_GHA_dec_t = [
    14 from_dm(26, 27.4) -from_dm(14, 33.7)
    15 from_dm(41, 27.4) -from_dm(14, 32.9)
    16 from_dm(56, 27.4) -from_dm(14, 32.1)
    17 from_dm(71, 27.4) -from_dm(14, 31.3)
    18 from_dm(86, 27.4) -from_dm(14, 30.5)
  ];

  jupiter_GHA_dec_t = [
    18 from_dm(68, 36.1) -from_dm(09, 00.0)
    19 from_dm(83, 38.0) -from_dm(08, 59.8)
  ];

  aries_GHA_t = [
    18 from_dm(49, 48.4)
    19 from_dm(64, 50.8)
    20 from_dm(79, 53.3)
  ];

  alpheratz_SHA_dec = [ from_dm(357, 37.5) from_dm(29, 12.7) ];
  hamal_SHA_dec     = [ from_dm(327, 54.0) from_dm(23, 34.0) ];
  deneb_SHA_dec     = [ from_dm( 49, 27.9) from_dm(45, 21.4) ];

  observation_GPs  = zeros(3, 0);
  observation_alts = zeros(1, 0);

  sun_id = 0;
  jupiter_id = 1;
  alpheratz_id = 2;
  hamal_id = 3;
  deneb_id = 4;

  observations = [
    from_hms(14, 15, 56) from_dm(11, 25.0) sun_id       sun_LL
    from_hms(17, 03, 41) from_dm( 2, 08.8) sun_id       sun_LL
    from_hms(17, 10, 05) from_dm( 1, 45.7) sun_id       sun_LL
    from_hms(17, 13, 30) from_dm( 1, 26.6) sun_id       sun_LL
    from_hms(17, 16, 20) from_dm( 1, 14.6) sun_id       sun_LL
    from_hms(17, 21, 30) from_dm( 1, 16.6) sun_id       sun_UL
    from_hms(17, 24, 25) from_dm( 0, 58.4) sun_id       sun_UL
    from_hms(18, 28, 23) from_dm( 6, 23.4) jupiter_id   0
    % Bad measurement conditions, bad data:
    % from_hms(19, 04, 54) from_dm(46, 08.2) alpheratz_id 0
    % from_hms(19, 08, 06) from_dm(49, 45.2) hamal_id     0
    % from_hms(19, 10, 13) from_dm(34, 27.2) deneb_id     0
    % from_hms(19, 17, 10) from_dm(56, 07.1) mirach_id    0
  ];

  for i = 1 : rows(observations)
    t = observations(i, 1);
    sextant_alt = observations(i, 2);
    id = observations(i, 3);
    limb_correction = observations(i, 4);

    observed_alt = corrected_altitude(sextant_alt, 0, eye_height, limb_correction);

    aries_GHA = interp1(aries_GHA_t(:, 1), aries_GHA_t(:, 2), t);

    switch id
      case sun_id
        GHA = interp1(sun_GHA_dec_t(:, 1), sun_GHA_dec_t(:, 2), t);
        dec = interp1(sun_GHA_dec_t(:, 1), sun_GHA_dec_t(:, 3), t);
      case jupiter_id
        GHA = interp1(jupiter_GHA_dec_t(:, 1), jupiter_GHA_dec_t(:, 2), t);
        dec = interp1(jupiter_GHA_dec_t(:, 1), jupiter_GHA_dec_t(:, 3), t);
      case alpheratz_id
        GHA = aries_GHA + alpheratz_SHA_dec(1);
        dec = alpheratz_SHA_dec(2);
      case hamal_id
        GHA = aries_GHA + hamal_SHA_dec(1);
        dec = hamal_SHA_dec(2);
      case deneb_id
        GHA = aries_GHA + deneb_SHA_dec(1);
        dec = deneb_SHA_dec(2);
      otherwise
        error("Unknown id: %s", id);
    endswitch

    observation_GPs(:, end + 1) = coord_to_vector(dec, -GHA);
    observation_alts(end + 1) = observed_alt;
  endfor

  position_fix([ 0; 0; 0 ], observation_GPs, observation_alts);

  printf("\n");
endfunction

location_1();
location_2();
location_3();
location_4();
