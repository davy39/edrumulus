%*******************************************************************************
% Copyright (c) 2020-2020
% Author: Volker Fischer
%*******************************************************************************
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.
%*******************************************************************************

% reference code for the C++ implementation on the actual hardware

function edrumulus(x)

global energy_window_len;
global rim_shot_window_len;

close all

% load test data
% x = audioread("signals/pd120_roll.wav");
% x = audioread("signals/pd120_single_hits.wav");
% x = audioread("signals/pd120_pos_sense.wav");%x = x(1:5000, :);%x = x(55400:58000, :);%
% x = audioread("signals/pd120_pos_sense2.wav");
x = audioread("signals/pd120_rimshot.wav");x = x(168000:171000, :);%x = x(1:8000, :);%x = x(1:34000, :);%x = x(1:100000, :);
% x = x(1300:5000); % * 1000;

% match the signal level of the ESP32
x = x * 25000;

Setup();

% loop
hil_debug            = zeros(size(x, 1), 1);
hil_filt_debug       = zeros(size(x, 1), 1);
hil_filt_decay_debug = zeros(size(x, 1), 1);
cur_decay_debug      = zeros(size(x, 1), 1);
rim_max_pow_debug    = zeros(size(x, 1), 1);
peak_found           = false(size(x, 1), 1);
peak_found_offset    = zeros(size(x, 1), 1);
pos_sense_metric     = zeros(size(x, 1), 1);
is_rim_shot          = false(size(x, 1), 1);

for i = 1:size(x, 1)

  [hil_debug(i), ...
   hil_filt_debug(i), ...
   hil_filt_decay_debug(i), ...
   cur_decay_debug(i), ...
   rim_max_pow_debug(i), ...
   peak_found(i), ...
   peak_found_offset(i), ...
   pos_sense_metric(i), ...
   is_rim_shot(i)] = process_sample(x(i, :));

end

% note that caused by the positional sensing/rim shot detection algorithms the peak detection is delayed
peak_found_idx                         = find(peak_found) - peak_found_offset(peak_found);
peak_found_corrected                   = false(size(peak_found));
peak_found_corrected(peak_found_idx)   = true;
is_rim_shot_idx                        = find(is_rim_shot);% - peak_found_offset(peak_found);
is_rim_shot_corrected                  = false(size(is_rim_shot));
is_rim_shot_corrected(is_rim_shot_idx) = true;

figure; plot(10 * log10(abs([hil_filt_debug, hil_filt_decay_debug, cur_decay_debug]))); hold on;
        plot(10 * log10(rim_max_pow_debug), 'y*');
        plot(find(peak_found_corrected), 10 * log10(hil_filt_debug(peak_found_corrected)), 'g*');
        plot(find(is_rim_shot_corrected), 10 * log10(hil_filt_debug(is_rim_shot_corrected)), 'b*');
        plot(find(peak_found_corrected), 10 * log10(pos_sense_metric(peak_found)) + 40, 'k*');
        ylim([-10, 90]);
% figure; plot(20 * log10(abs([x, hil_debug, hil_filt_debug])));

return;


% TEST
pkg load instrument-control

% prepare serial port
try
  a = serialport("COM7", 115200);
catch
end
flush(a);

bReturnIsComplex = false;

% send the input data vector
for i = 1:length(x)

  % write sample
  write(a, sprintf('%f.6\n', x(i)), 'char');

  % receive the return sample
  if bReturnIsComplex

    for j = 1:2

      % get number from string
      readready = false;
      bytearray = uint8([]);

      while ~readready

        val = fread(a, 1);

        if val == 13
          readready = true;
        end

        bytearray = [bytearray, uint8(val)];

      end

      y(2 * (i - 1) + j) = str2double(char(bytearray));

    end

  else

      % get number from string
      readready = false;
      bytearray = uint8([]);

      while ~readready

        val = fread(a, 1);

        if val == 13
          readready = true;
        end

        bytearray = [bytearray, uint8(val)];

      end

      y(i) = str2double(char(bytearray));

  end

end

if bReturnIsComplex
  y = complex(y(1:2:2 * length(x)), y(2:2:2 * length(x)));
end


% figure; plot([peak_found, y.'], '*');
figure; plot(20 * log10(abs([hil_filt_debug, y.'])));
% figure; plot(20 * log10(abs([x, y.'])));
% figure; plot(abs(x.' - y));


end





function Setup

global Fs;
global a_re;
global a_im;
global hil_filt_len;
global hil_hist;
global energy_window_len;
global scan_time;
global scan_time_cnt;
global mov_av_hist_re;
global mov_av_hist_im;
global mask_time;
global mask_back_cnt;
global threshold;
global was_above_threshold;
global prev_hil_filt_val;
global prev_hil_filt_decay_val;
global decay_fact;
global decay_len;
global decay;
global decay_back_cnt;
global decay_scaling;
global alpha;
global hil_low_re;
global hil_low_im;
global hil_hist_re;
global hil_hist_im;
global hil_low_hist_re;
global hil_low_hist_im;
global peak_energy_hist_len;
global peak_energy_hist;
global peak_energy_low_hist;
global pos_sense_cnt;
global rim_shot_window_len;
global rim_shot_threshold;
global x_rim_hil_hist;
global x_rim_hil_hist_re;
global x_rim_hil_hist_im;
global rim_shot_cnt;
global stored_pos_sense_metric;
global max_hil_filt_val;
global max_hil_filt_decay_val;
global peak_found_offset;

Fs           = 8000;
hil_filt_len = 7;
hil_hist     = zeros(hil_filt_len, 1); % memory allocation for hilbert filter history
a_re = [-0.037749783581601, -0.069256807147465, -1.443799477299919,  2.473967088799056, ...
         0.551482327389238, -0.224119735833791, -0.011665324660691]';
a_im = [ 0,                  0.213150535195075, -1.048981722170302, -1.797442302898130, ...
         1.697288080048948,  0,                  0.035902177664014]';
energy_window_len       = round(2e-3 * Fs); % scan time (e.g. 2 ms)
scan_time               = round(1e-3 * Fs); % scan time from first detected peak
scan_time_cnt           = 0;
mov_av_hist_re          = zeros(energy_window_len, 1); % real part memory for moving average filter history
mov_av_hist_im          = zeros(energy_window_len, 1); % imaginary part memory for moving average filter history
mask_time               = round(10e-3 * Fs); % mask time (e.g. 10 ms)
mask_back_cnt           = 0;
threshold               = power(10, 23 / 10); % 23 dB threshold
was_above_threshold     = false;
prev_hil_filt_val       = 0;
prev_hil_filt_decay_val = 0;
decay_fact              = power(10, 1 / 10); % decay factor of 1 dB
decay_len               = round(0.25 * Fs); % decay time (e.g. 250 ms)
decay_grad              = 200 / Fs; % decay gradient factor
decay                   = power(10, -(0:decay_len - 1) / 10 * decay_grad);
decay_back_cnt          = 0;
decay_scaling           = 1;
alpha                   = 200 / Fs;
hil_low_re              = 0;
hil_low_im              = 0;
pos_sense_cnt           = 0;
hil_hist_re             = zeros(energy_window_len, 1);
hil_hist_im             = zeros(energy_window_len, 1);
hil_low_hist_re         = zeros(energy_window_len, 1);
hil_low_hist_im         = zeros(energy_window_len, 1);
peak_energy_hist_len    = scan_time + energy_window_len / 2 + 1;
peak_energy_hist        = zeros(peak_energy_hist_len, 1);
peak_energy_low_hist    = zeros(peak_energy_hist_len, 1);
rim_shot_window_len     = round(6e-3 * Fs); % window length (e.g. 6 ms)
rim_shot_threshold      = 10 ^ (87.5 / 10);
x_rim_hil_hist          = zeros(hil_filt_len, 1);
x_rim_hil_hist_re       = zeros(rim_shot_window_len, 1);
x_rim_hil_hist_im       = zeros(rim_shot_window_len, 1);
rim_shot_cnt            = 0;
stored_pos_sense_metric = 0;
max_hil_filt_val        = 0;
max_hil_filt_decay_val  = 0;
peak_found_offset       = 0;

end


function fifo_memory = update_fifo ( input, ...
                                     fifo_length, ...
                                     fifo_memory )

  % move all values in the history one step back and put new value on the top
  fifo_memory(1:fifo_length - 1) = fifo_memory(2:fifo_length);
  fifo_memory(fifo_length)       = input;

end


function [hil_debug, ...
          hil_filt_debug, ...
          hil_filt_decay_debug, ...
          cur_decay_debug, ...
          rim_max_pow_debug, ...
          peak_found, ...
          peak_found_offset, ...
          pos_sense_metric, ...
          is_rim_shot] = process_sample(x)

global Fs;
global a_re;
global a_im;
global hil_filt_len;
global hil_hist;
global energy_window_len;
global scan_time;
global scan_time_cnt;
global mov_av_hist_re;
global mov_av_hist_im;
global mask_time;
global mask_back_cnt;
global threshold;
global was_above_threshold;
global prev_hil_filt_val;
global prev_hil_filt_decay_val;
global decay_fact;
global decay_len;
global decay;
global decay_back_cnt;
global decay_scaling;
global alpha;
global hil_low_re;
global hil_low_im;
global hil_hist_re;
global hil_hist_im;
global hil_low_hist_re;
global hil_low_hist_im;
global peak_energy_hist_len;
global peak_energy_hist;
global peak_energy_low_hist;
global pos_sense_cnt;
global rim_shot_window_len;
global rim_shot_threshold;
global x_rim_hil_hist;
global x_rim_hil_hist_re;
global x_rim_hil_hist_im;
global rim_shot_cnt;
global stored_pos_sense_metric;
global max_hil_filt_val;
global max_hil_filt_decay_val;
global peak_found_offset;


% initialize return parameter
peak_found        = false;
pos_sense_metric  = 0;
is_rim_shot       = false;
cur_decay_debug   = 0; % just for debugging
rim_max_pow_debug = 0; % just for debugging


% Calculate peak detection -----------------------------------------------------
% hilbert filter
hil_hist = update_fifo(x(1), hil_filt_len, hil_hist);
hil_re   = sum(hil_hist .* a_re);
hil_im   = sum(hil_hist .* a_im);

hil_debug = complex(hil_re, hil_im); % just for debugging


% moving average filter
mov_av_hist_re = update_fifo(hil_re, energy_window_len, mov_av_hist_re);
mov_av_hist_im = update_fifo(hil_im, energy_window_len, mov_av_hist_im);
mov_av_re      = sum(mov_av_hist_re) / energy_window_len;
mov_av_im      = sum(mov_av_hist_im) / energy_window_len;

hil_filt = mov_av_re * mov_av_re + mov_av_im * mov_av_im;

hil_filt_debug = hil_filt; % just for debugging


% exponential decay assumption (note that we must not use hil_filt_org since a
% previous peak might not be faded out and the peak detection works on hil_filt)
% subtract decay (with clipping at zero)
if decay_back_cnt > 0

  cur_decay       = decay_scaling * decay(1 + decay_len - decay_back_cnt);
  cur_decay_debug = cur_decay; % just for debugging
  hil_filt_decay  = hil_filt - cur_decay;
  decay_back_cnt  = decay_back_cnt - 1;

  if hil_filt_decay < 0
    hil_filt_decay = 0;
  end

else
  hil_filt_decay = hil_filt;
end


% threshold test
if ((hil_filt_decay > threshold) || was_above_threshold) && (mask_back_cnt == 0)

  was_above_threshold = true;

  % climb to the maximum of the first peak
  if (prev_hil_filt_decay_val < hil_filt_decay) && (scan_time_cnt == 0)

    prev_hil_filt_decay_val = hil_filt_decay;
    prev_hil_filt_val       = hil_filt; % needed for further processing

  else

    % start condition of scan time
    if scan_time_cnt == 0

      % search in a pre-defined scan time for the highest peak
      scan_time_cnt          = scan_time;               % initialize scan time counter
      max_hil_filt_decay_val = prev_hil_filt_decay_val; % initialize maximum value with first peak
      max_hil_filt_val       = prev_hil_filt_val;       % initialize maximum value with first peak
      peak_found_offset      = scan_time;               % position of first peak after scan time expired

    end

    % search for a maximum in the scan time interval
    if hil_filt_decay > max_hil_filt_decay_val

      max_hil_filt_decay_val = hil_filt_decay;
      max_hil_filt_val       = hil_filt;          % we need to store the origianl Hilbert filtered signal for the decay
      peak_found_offset      = scan_time_cnt - 1; % update position of detected peak

    end

    scan_time_cnt = scan_time_cnt - 1;

    % end condition of scan time
    if scan_time_cnt == 0

      % scan time expired
      prev_hil_filt_decay_val = 0;
      was_above_threshold     = false;
      decay_scaling           = max_hil_filt_val * decay_fact;
      decay_back_cnt          = decay_len - peak_found_offset;
      mask_back_cnt           = mask_time - peak_found_offset;
      peak_found              = true;

    end

  end

end

if mask_back_cnt > 0
  mask_back_cnt = mask_back_cnt - 1;
end

hil_filt_decay_debug = hil_filt_decay; % just for debugging


% Calculate positional sensing -------------------------------------------------
% low pass filter of the Hilbert signal
hil_low_re = (1 - alpha) * hil_low_re + alpha * hil_re;
hil_low_im = (1 - alpha) * hil_low_im + alpha * hil_im;

hil_hist_re     = update_fifo(hil_re,     energy_window_len, hil_hist_re);
hil_hist_im     = update_fifo(hil_im,     energy_window_len, hil_hist_im);
hil_low_hist_re = update_fifo(hil_low_re, energy_window_len, hil_low_hist_re);
hil_low_hist_im = update_fifo(hil_low_im, energy_window_len, hil_low_hist_im);

peak_energy     = sum(hil_hist_re     .* hil_hist_re     + hil_hist_im     .* hil_hist_im);
peak_energy_low = sum(hil_low_hist_re .* hil_low_hist_re + hil_low_hist_im .* hil_low_hist_im);

% store the peak energies
peak_energy_hist     = update_fifo(peak_energy,     peak_energy_hist_len, peak_energy_hist);
peak_energy_low_hist = update_fifo(peak_energy_low, peak_energy_hist_len, peak_energy_low_hist);

if peak_found || (pos_sense_cnt > 0)

  % start condition of delay process to fill up the required buffers
  if pos_sense_cnt == 0

    % a peak was found, we now have to start the delay process to fill up the
    % required buffer length for our metric

% TODO IS THIS CORRECT?????
pos_sense_cnt = max(1, energy_window_len / 2 + 1 - peak_found_offset);

    peak_found = false; % will be set after delay process is done

  end

  pos_sense_cnt = pos_sense_cnt - 1;

  % end condition
  if pos_sense_cnt == 0

    % the buffers are filled, now calculate the metric
    peak_energy_hist_idx = peak_energy_hist_len - peak_found_offset + energy_window_len / 2 - 1;
    pos_sense_metric     = peak_energy_hist(peak_energy_hist_idx) / peak_energy_low_hist(peak_energy_hist_idx);
    peak_found           = true;

  else

    % we need a further delay for the positional sensing estimation, consider
    % this additional delay for the overall peak found offset
    peak_found_offset = peak_found_offset + 1;

  end

end


%% Calculate rim shot detection -------------------------------------------------
%if length(x) > 1 % rim piezo signal is in second dimension
%
%  % hilbert filter
%  x_rim_hil_hist = update_fifo(x(2), hil_filt_len, x_rim_hil_hist);
%  x_rim_hil_re   = sum(x_rim_hil_hist .* a_re);
%  x_rim_hil_im   = sum(x_rim_hil_hist .* a_im);
%
%  x_rim_hil_hist_re = update_fifo(x_rim_hil_re, rim_shot_window_len, x_rim_hil_hist_re);
%  x_rim_hil_hist_im = update_fifo(x_rim_hil_im, rim_shot_window_len, x_rim_hil_hist_im);
%
%  % note that rim_shot_window_len must be larger than energy_window_len for this to work
%  if peak_found || (rim_shot_cnt > 0)
%
%    if peak_found && (rim_shot_cnt == 0)
%
%      % a peak was found, we now have to start the delay process to fill up the
%      % required buffer length for our metric
%      rim_shot_cnt            = rim_shot_window_len / 2 - energy_window_len / 2;
%      peak_found              = false; % will be set after delay process is done
%      stored_pos_sense_metric = pos_sense_metric;
%
%    elseif rim_shot_cnt == 1
%
%      % the buffers are filled, now calculate the metric
%      rim_max_pow       = max(x_rim_hil_hist_re .* x_rim_hil_hist_re + x_rim_hil_hist_im .* x_rim_hil_hist_im);
%      rim_max_pow_debug = rim_max_pow; % just for debugging
%      is_rim_shot       = rim_max_pow > rim_shot_threshold;
%      rim_shot_cnt      = 0;
%      peak_found        = true;
%      pos_sense_metric  = stored_pos_sense_metric;
%
%    else
%
%      % we still need to wait for the buffers to fill up
%      rim_shot_cnt = rim_shot_cnt - 1;
%
%    end
%
%  end
%
%end

end


