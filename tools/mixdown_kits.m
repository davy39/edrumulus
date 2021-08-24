%*******************************************************************************
% Copyright (c) 2020-2021
% Author(s): Volker Fischer
%*******************************************************************************
% This program is free software; you can redistribute it and/or modify it under
% the terms of the GNU General Public License as published by the Free Software
% Foundation; either version 2 of the License, or (at your option) any later
% version.
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
% You should have received a copy of the GNU General Public License along with
% this program; if not, write to the Free Software Foundation, Inc.,
% 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
%*******************************************************************************

pkg load signal

% sampling rate depends on the kit
sampling_rate = 44100;

% base paths
out_kit_name  = 'edrumuluskit';
out_kit_path  = [out_kit_name '/'];
samples_path  = 'samples/';
mixed_prefix  = 'mixed_';
midi_map_name = [out_kit_name '_midimap'];

% kit select or optional instrument select
kit_select        = [];%3; % if [], the instrument_select is used otherwise the entire selected kit number
instrument_select = {2, 'snare_rim_shot', 1.5; ... % gain boost of rim shot
                     3, 'CrashL',           0; ...
                     3, 'HihatClosed',      0; ...
                     3, 'HihatOpen',        0; ...
                     3, 'KDrumL',           0; ...
                     3, 'RideR',            0; ...
                     3, 'RideRBell',        0; ...
                     3, 'Snare',            0; ...
                     3, 'Tom1',             0; ...
                     3, 'Tom2',             0};

% kit properties, where, e.g., channel names and audio mix matrix are
% defined (left/right channels output gain for each channel)
% kit_channel_properties: CH name instr, CH name kit, gainL, gainR, eq1_gain, eq1_freq, eq1_BW, eq2_gain, eq2_freq, eq2_BW
kit_path               = {};
kit_channel_properties = {};
kit_midi_map           = {};

kit_path{1} = 'DRSKit/'; % DRSKit ----------------------------------------------
if 1
kit_channel_properties{1} = {'AmbL',         'AmbL',          -2, -90,   0,  10000,  0.5,   0,  10000, 0.5; ...
                             'AmbR',         'AmbR',         -90,  -2,   0,  10000,  0.5,   0,  10000, 0.5; ...
                             'Hihat',        'Hihat',         -2,  -2, -20,    500,  0.7,   0,  10000, 0.5; ...
                             'Kdrum_back',   'Kdrum_back',    -4,  -4,  15,     70, 0.08, -10,    400, 0.2; ...
                             'Kdrum_front',  'Kdrum_front',   -4,  -4,   2,   6000,  0.4,  15,     70, 0.05; ...
                             'OHL',          'OHL',           -6, -90, -20,    500,  0.7,  10,  10000, 0.4; ...
                             'OHR',          'OHR',          -90,  -6, -20,    500,  0.7,  10,  10000, 0.4; ...
                             'Ride',         'Ride',          -2,  -2, -20,    500,  0.7,  10,  10000, 0.5; ...
                             'Snare_bottom', 'Snare_bottom',  -6,  -6,  10,   6000,  0.4,   0,  10000, 0.5; ...
                             'Snare_top',    'Snare_top',     -3,  -3,  10,    120,  0.2,  12,  10000, 0.5; ...
                             'Tom1',         'Tom1',           0,   0,   5,    100,  0.2,   0,  10000, 0.5; ...
                             'Tom2',         'Tom2',           0,   0,   0,  10000,  0.5,   0,  10000, 0.5; ...
                             'Tom3',         'Tom3',           0,   0,   0,  10000,  0.5,   0,  10000, 0.5};
else % convenient settings for soloing one instrument:
kit_channel_properties{1} = {'AmbL',         'AmbL',         -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'AmbR',         'AmbR',         -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Hihat',        'Hihat',        -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Kdrum_back',   'Kdrum_back',   -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Kdrum_front',  'Kdrum_front',  -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'OHL',          'OHL',          -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'OHR',          'OHR',          -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Ride',         'Ride',         -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Snare_bottom', 'Snare_bottom', -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Snare_top',    'Snare_top',    -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Tom1',         'Tom1',         -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Tom2',         'Tom2',         -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Tom3',         'Tom3',         -90, -90,   0,  10000, 0.5,   0,  10000, 0.5};
end
kit_midi_map{1} = {'Crash_left_shank',   {55, 49}; ...
                   'Hihat_closed_shank', 22; ...
                   'Hihat_semi_open',    26; ...
                   'Kdrum_with_contact', 36; ...
                   'Ride_tip',           51; ...
                   'Ride_shank_bell',    66; ...
                   'Snare',              38; ...
                   'Snare',              40; ...
                   'Tom1',               48; ...
                   'Tom2',               45};

kit_path{2} = 'aasimonster2/'; % aasimonster2 ----------------------------------
if 1
kit_channel_properties{2} = {'Alesis',        'Trigger',       -90, -90,   0,  10000,  0.5,   0,  10000, 0.5; ...
                             'Amb L',         'AmbL',           -9, -90,   0,  10000,  0.5,   0,  10000, 0.5; ...
                             'Amb R',         'AmbR',          -90,  -9,   0,  10000,  0.5,   0,  10000, 0.5; ...
                             'Hihat',         'Hihat',          -2,  -2, -20,    500,  0.7,   5,  10000, 0.3; ...
                             'Kick L',        'KdrumL',          0,   0,  10,     70, 0.08, -10,    400, 0.2; ...
                             'Kick R',        'KdrumR',        -90, -90,   0,  10000,  0.5,   0,  10000, 0.5; ...
                             'OH L',          'OHL',            -9, -90, -20,    500,  0.7,  10,  10000, 0.4; ...
                             'OH R',          'OHR',           -90,  -9, -20,    500,  0.7,  10,  10000, 0.4; ...
                             'Ride',          'Ride',           -2,  -2, -20,    500,  0.7,  10,  10000, 0.5; ...
                             'Snare bottom',  'Snare_bottom',   -4,  -4,   0,  10000,  0.5,   0,  10000, 0.5; ...
                             'Snare top',     'Snare_top',      -4,  -4, -18,    800, 0.15,   5,   8000, 0.3; ...
                             'Snare trigger', 'Snare_trigger', -90, -90,   0,  10000,  0.5,   0,  10000, 0.5; ...
                             'Tom1',          'Tom1',           -1,  -1,   0,  10000,  0.5,   0,  10000, 0.5; ...
                             'Tom2',          'Tom2',           -1,  -1,   0,  10000,  0.5,   0,  10000, 0.5; ...
                             'Tom3',          'Tom3',           -1,  -1,   0,  10000,  0.5,   0,  10000, 0.5; ...
                             'Tom4',          'Tom4',           -1,  -1,   0,  10000,  0.5,   0,  10000, 0.5};
else % convenient settings for soloing one instrument:
kit_channel_properties{2} = {'Alesis',        'Trigger',       -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Amb L',         'AmbL',          -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Amb R',         'AmbR',          -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Hihat',         'Hihat',         -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Kick L',        'KdrumL',        -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Kick R',        'KdrumR',        -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'OH L',          'OHL',           -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'OH R',          'OHR',           -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Ride',          'Ride',          -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Snare bottom',  'Snare_bottom',  -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Snare top',     'Snare_top',     -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Snare trigger', 'Snare_trigger', -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Tom1',          'Tom1',          -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Tom2',          'Tom2',          -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Tom3',          'Tom3',          -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Tom4',          'Tom4',          -90, -90,   0,  10000, 0.5,   0,  10000, 0.5};
end
kit_midi_map{2} = {'crash1',          {55, 49}; ...
                   'hihat_closed1',   22; ...
                   'hihat_open',      26; ...
                   'kick_l',          36; ...
                   'ride',            51; ...
                   'ride_bell1',      66; ...
                   'snare_on_center', 38; ...
                   'snare_rim_shot',  40; ...
                   'tom_1',           48; ...
                   'tom_2',           45};

kit_path{3} = 'CrocellKit/'; % CrocellKit --------------------------------------
if 1
kit_channel_properties{3} = {'AmbLeft',      'AmbLeft',        3, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'AmbRight',     'AmbRight',     -90,   3,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'FTom1',        'FTom1',          0,   0,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'FTom2',        'FTom2',          0,   0,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Hihat',        'Hihat',          7,   7,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'KDrumInside',  'KDrumInside',    6,   6,   8,     70, 0.1,   3,   6000, 0.3; ...
                             'KDrumOutside', 'KDrumOutside',   7,   7,   3,     70, 0.1,  15,   8000, 0.1; ...
                             'OHCenter',     'OHCenter',      -3,  -3,   0,    500, 0.7,  10,  10000, 0.4; ...
                             'OHLeft',       'OHLeft',        -1, -90, -20,    500, 0.7,  10,  10000, 0.4; ...
                             'OHRight',      'OHRight',      -90,  -1, -20,    500, 0.7,  10,  10000, 0.4; ...
                             'Ride',         'Ride',           0,   0,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'SnareBottom',  'SnareBottom',   -3,  -3,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'SnareTop',     'SnareTop',      -3,  -3,   6,    150, 0.1,  11,   8000, 0.3; ...
                             'Tom1',         'Tom1',           0,   0,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Tom2',         'Tom2',           0,   0,   0,  10000, 0.5,   0,  10000, 0.5};
else % convenient settings for soloing one instrument:
kit_channel_properties{3} = {'AmbLeft',      'AmbLeft',      -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'AmbRight',     'AmbRight',     -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'FTom1',        'FTom1',        -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'FTom2',        'FTom2',        -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Hihat',        'Hihat',        -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'KDrumInside',  'KDrumInside',  -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'KDrumOutside', 'KDrumOutside', -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'OHCenter',     'OHCenter',     -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'OHLeft',       'OHLeft',       -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'OHRight',      'OHRight',      -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Ride',         'Ride',         -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'SnareBottom',  'SnareBottom',  -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'SnareTop',     'SnareTop',     -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Tom1',         'Tom1',         -90, -90,   0,  10000, 0.5,   0,  10000, 0.5; ...
                             'Tom2',         'Tom2',         -90, -90,   0,  10000, 0.5,   0,  10000, 0.5};
end
kit_midi_map{3} = {'CrashL',       {55, 49}; ...
                   'HihatClosed',  22; ...
                   'HihatOpen',    26; ...
                   'KDrumL',       36; ...
                   'RideR',        51; ...
                   'RideRBell',    66; ...
                   'Snare',        38; ...
                   'SnareRimShot', 40; ...
                   'Tom1',         48; ...
                   'Tom2',         45};


% create MIDI map either from complete kit MIDI map or selected instruments
if ~isempty(kit_select)
  midi_map = kit_midi_map{kit_select};
else
  for instrument_index = 1:size(instrument_select, 1)
    current_kit_idx                = instrument_select{instrument_index, 1};
    current_kit_instrument_log_idx = strcmp(kit_midi_map{current_kit_idx}(:, 1), instrument_select(instrument_index, 2));
    midi_map(instrument_index, :)  = kit_midi_map{current_kit_idx}(current_kit_instrument_log_idx, :);
  end
end

% initialization
mkdir(out_kit_path);

% create kit XML file (only use instruments which are defined in the MIDI map)
file_id = fopen([out_kit_path out_kit_name '.xml'], 'w');
fwrite(file_id, ['<?xml version="1.0" encoding="UTF-8"?>' char(10)]);
fwrite(file_id, ['<drumkit name="' out_kit_name '" description="Mixed Drumgizmo drum kit">' char(10)]);
fwrite(file_id, ['  <channels>' char(10)]);
fwrite(file_id, ['      <channel name="left_channel"/>' char(10)]);
fwrite(file_id, ['      <channel name="right_channel"/>' char(10)]);
fwrite(file_id, ['    </channels>' char(10)]);
fwrite(file_id, ['    <instruments>' char(10)]);
for midi_map_index = 1:size(midi_map, 1)
  if strfind(toupper(midi_map{midi_map_index, 1}), 'HIHAT')
    fwrite(file_id, ['    <instrument name="' midi_map{midi_map_index, 1} '" group="hihat" file="' midi_map{midi_map_index, 1} '/' midi_map{midi_map_index, 1} '.xml">' char(10)]);
  else
    fwrite(file_id, ['    <instrument name="' midi_map{midi_map_index, 1} '" file="' midi_map{midi_map_index, 1} '/' midi_map{midi_map_index, 1} '.xml">' char(10)]);
  end
  fwrite(file_id, ['      <channelmap in="left_channel" out="left_channel" main="true"/>' char(10)]);
  fwrite(file_id, ['      <channelmap in="right_channel" out="right_channel" main="true"/>' char(10)]);
  fwrite(file_id, ['    </instrument>' char(10)]);
end
fwrite(file_id, ['  </instruments>' char(10)]);
fwrite(file_id, ['</drumkit>' char(10)]);
fclose(file_id);

% create MIDI map XML file
file_id = fopen([out_kit_path midi_map_name '.xml'], 'w');
fwrite(file_id, ['<?xml version="1.0" encoding="UTF-8"?>' char(10)]);
fwrite(file_id, ['<midimap>' char(10)]);
for midi_map_index = 1:size(midi_map, 1)
  if iscell(midi_map{midi_map_index, 2})
    for midi_index = 1:length(midi_map{midi_map_index, 2})
      fwrite(file_id, ['  <map note="' num2str(midi_map{midi_map_index, 2}{midi_index}) '" instr="' midi_map{midi_map_index, 1} '"/>' char(10)]); 
    end
  else
    fwrite(file_id, ['  <map note="' num2str(midi_map{midi_map_index, 2}) '" instr="' midi_map{midi_map_index, 1} '"/>' char(10)]); 
  end
end
fwrite(file_id, ['</midimap>' char(10)]);
fclose(file_id);

% loop over all instruments
for instrument_index = 1:length(midi_map)

  disp(['Current instrument: ' midi_map{instrument_index, 1}]);

  % select current instrument properties
  if ~isempty(kit_select)

    current_kit_path   = kit_path{kit_select};
    channel_properties = kit_channel_properties{kit_select};
    instrument_gain    = 1; % no gain modification for using an entire kit

  else

    current_kit_idx    = instrument_select{instrument_index, 1};
    current_kit_path   = kit_path{current_kit_idx};
    channel_properties = kit_channel_properties{current_kit_idx};
    instrument_gain    = 10 .^ (instrument_select{instrument_index, 3} / 20);

  end

  % get current instrument path
  file_path = [midi_map{instrument_index, 1} '/'];

  % get instrument XML file name
  instr_root_dir      = dir([current_kit_path file_path]);
  xml_file_name_index = find(~[instr_root_dir.isdir]);
  [~, xml_file_name]  = fileparts(instr_root_dir(xml_file_name_index).name);

  % get instrument samples file names
  instr_samples_dir = dir([current_kit_path file_path samples_path]);

  % load and modify instrument XML
  file_id           = fopen([current_kit_path file_path xml_file_name '.xml'], 'r');
  end_of_file_found = false;
  cnt               = 1;
  xml_file          = {};

  while ~end_of_file_found
    xml_file{cnt} = fgetl(file_id);

    if xml_file{cnt} < 0
      xml_file          = xml_file(1:end - 1); % cut invalid line
      end_of_file_found = true;
    else

      % add prefix for mixed signal to the sample name
      if strfind(xml_file{cnt}, 'sample name="')
        insert_position = strfind(xml_file{cnt}, 'sample name="') + length('sample name="') - 1;
        xml_file{cnt}   = [xml_file{cnt}(1:insert_position) mixed_prefix xml_file{cnt}(insert_position + 1:end)];
      end

      % exchange names of first two channels (left/right channel)
      if strfind(xml_file{cnt}, ['audiofile channel="' channel_properties{1, 1}])
        xml_file{cnt}   = strrep(xml_file{cnt}, ['audiofile channel="' channel_properties{1, 1}], ['audiofile channel="left_channel']);
        insert_position = strfind(xml_file{cnt}, ['file="' samples_path]) + length(['file="' samples_path]) - 1;
        xml_file{cnt}   = [xml_file{cnt}(1:insert_position) mixed_prefix xml_file{cnt}(insert_position + 1:end)];
      end
      if strfind(xml_file{cnt}, ['audiofile channel="' channel_properties{2, 1}])
        xml_file{cnt}   = strrep(xml_file{cnt}, ['audiofile channel="' channel_properties{2, 1}], ['audiofile channel="right_channel']);
        insert_position = strfind(xml_file{cnt}, ['file="' samples_path]) + length(['file="' samples_path]) - 1;
        xml_file{cnt}   = [xml_file{cnt}(1:insert_position) mixed_prefix xml_file{cnt}(insert_position + 1:end)];
      end

      % remove all other channels
      for channel_properties_index = 3:size(channel_properties, 1)
        if strfind(xml_file{cnt}, ['audiofile channel="' channel_properties{channel_properties_index, 1}])
          cnt = cnt - 1;
        end
      end

      cnt = cnt + 1;

    end
  end

  fclose(file_id);

  % write modified instrument XML file
  mkdir([out_kit_path file_path]);
  file_id = fopen([out_kit_path file_path xml_file_name '.xml'], 'w');
  for line_index = 1:length(xml_file)
    fwrite(file_id, xml_file{line_index});
    fwrite(file_id, 10);
  end
  fclose(file_id);


% TEST find loudest sample for debugging
sample_numbers = zeros(length(instr_samples_dir), 1);
for sample_index = 1:length(instr_samples_dir)
  if ~instr_samples_dir(sample_index).isdir
    [~, file_name]               = fileparts(instr_samples_dir(sample_index).name);
    sample_numbers(sample_index) = str2double(cell2mat(regexp(file_name, '\d*', 'Match')));
  end
end
[~, highest_sample_number_sample_index] = max(sample_numbers);


  % mix and process instrument samples
  for sample_index = 1:length(instr_samples_dir)

    if ~instr_samples_dir(sample_index).isdir

      % get current sample file name
      [~, file_name] = fileparts(instr_samples_dir(sample_index).name);

      % load wave file
      x_all = audioread([current_kit_path file_path samples_path file_name '.wav']);

      % equalizer
      for channel_index = 1:size(x_all, 2)

        % parametric equalizer, channel 1
        filter_frequency = cell2mat(channel_properties(channel_index, 6));
        filter_bandwidth = cell2mat(channel_properties(channel_index, 7));
        filter_gain      = cell2mat(channel_properties(channel_index, 5));

        if filter_gain ~= 0
          w      = 2 * tan(2 * pi * filter_frequency / sampling_rate / 2);
          [b, a] = bilinear([1, 2 * filter_bandwidth * 10 ^ (filter_gain / 20) * w, w ^ 2], [1, 2 * filter_bandwidth * w, w ^ 2], 1);
          x_all(:, channel_index) = filter(b, a, x_all(:, channel_index));
        end

        % parametric equalizer, channel 2
        filter_frequency = cell2mat(channel_properties(channel_index,  9));
        filter_bandwidth = cell2mat(channel_properties(channel_index, 10));
        filter_gain      = cell2mat(channel_properties(channel_index,  8));

        if filter_gain ~= 0
          w      = 2 * tan(2 * pi * filter_frequency / sampling_rate / 2);
          [b, a] = bilinear([1, 2 * filter_bandwidth * 10 ^ (filter_gain / 20) * w, w ^ 2], [1, 2 * filter_bandwidth * w, w ^ 2], 1);
          x_all(:, channel_index) = filter(b, a, x_all(:, channel_index));
        end

      end

      % mix channels
      mix_matrix = 10 .^ (cell2mat(channel_properties(:, 3:4)) / 20);
      x_left     = x_all * mix_matrix(:, 1);
      x_right    = x_all * mix_matrix(:, 2);
      x          = [x_left, x_right] * instrument_gain;


% TEST
% play the resulting wave form
if (size(instrument_select, 1) == 1) && (sample_index == highest_sample_number_sample_index)
  player = audioplayer(x, sampling_rate, 16);
  play(player);
  pause(1);
end


      % store the resulting wave file
      mkdir([out_kit_path file_path samples_path]);
      audiowrite([out_kit_path file_path samples_path mixed_prefix file_name '.wav'], x, sampling_rate);

    end

  end

end
