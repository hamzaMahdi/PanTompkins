function Hd = bandpassFilt
%BANDPASSFILT Returns a discrete-time filter object.

% MATLAB Code
% Generated by MATLAB(R) 9.3 and Signal Processing Toolbox 7.5.
% Generated on: 19-Oct-2018 16:32:34

% Butterworth Bandpass filter designed using FDESIGN.BANDPASS.

% All frequency values are in Hz.
Fs = 200;  % Sampling Frequency

N   = 10;   % Order
Fc1 = 0.5;  % First Cutoff Frequency
Fc2 = 20;   % Second Cutoff Frequency

% Construct an FDESIGN object and call its BUTTER method.
h  = fdesign.bandpass('N,F3dB1,F3dB2', N, Fc1, Fc2, Fs);
Hd = design(h, 'butter');

% [EOF]
