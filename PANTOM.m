%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%              Lab 3: ECG Beat Detection and Rhythm Analysis            %
%                                                                       %
%       Part I:  QRS Beat Detection using Pan-TompKins Algorithm        %
%                                                                       %
%               Created by Dr. Sridhar Krishnan,                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clear all
fnam = input('Enter the ECG file name :','s');
fid = fopen(fnam);
ecg = fscanf(fid,'%f ');
sze = size(ecg,1);
necg = ecg/max(ecg);
p0 = necg;
fs = 200;
t= [1:length(p0)]/fs;

%%%%%%%%%%%%%NOTCH%%%%%%%%%%%%%
% define notch filter coefficient arrays a and b
OmegaZero = 2 * pi * (60 / 200);
z1 = cos(OmegaZero) + 1i * sin(OmegaZero);
z2 = cos(-OmegaZero) + 1i * sin(-OmegaZero);
b_notch = [1 -z1+-z2 z1*z2]/(1-z1+-z2+z1*z2);%normalized by dividing
% H(z) = Gain * (b(1) + b(2)z^-1 + b(3)z^-2)
% H(z=1) = Gain * (b(1) + b(2)1 + b(3)1) = 1
a_notch = [1 0 0];
%p0 = filter(b_notch,a_notch,p0);

%bp = filter(band_pass,p0)
%low pass filter 
b_low = zeros(1,13);
b_low(1) = (1/32); b_low(7) = -(2/32); b_low(13) = (1/32);
a_low  = [1 -2 1];
b_high = zeros(1,33); 
b_high(1) = -(1/32); b_high(17) = 1; b_high(18) = -1; b_high(33) = (1/32);
a_high = [1 -1];

b = conv(b_low,b_high);
a = conv(a_low,a_high);
bp = filter(b,a,p0);

subplot(211);plot(necg);
subplot(212);plot(bp);



%%% High pass filter (Allpass-lowpass) %%%


%%% Derivative %%%
b_der = [2 1 0 -1 -2]/8;
a_der = [1];
der = filter(b_der,a_der,bp);
figure;plot(der);
%%% Squaring %%%
square = der.^2;
figure;plot(square)

%%% Moving window integral %%%
a_int = 1;
b_int= ones(1,30)/30;
integral = filter(b_int,a_int,square);
figure;plot(integral)

%%%%%% Blanking %%%%%%%%
signal = integral;
peaks=[];Pindex = 0;
window = 30;
for i = window:(length(signal)-window+1)
    current_sample  = signal(i);
    range  = i-(window-1):i+(window-1);
    maximum  = max(signal(range));
    if(current_sample>=maximum)
        Pindex = Pindex+1;
        peaks(Pindex) = i;
    end
end
%%%%%% Thresholding %%%%%%%
SPKI = max(signal)*0.6;NPKI = max(signal)*0.3;%idk 
Threshold = NPKI + 0.25 * (SPKI - NPKI);

QRS = [];Qindex = 0;


for i = 1: length(peaks) % Loop through all the values of PeakIndex    
    if signal(peaks(i)) > Threshold % If the current sample exceeds the threshold value
                
        SPKI = (0.125 * signal(peaks(i))) + (0.875 * SPKI); 
        Qindex = Qindex + 1;         
        QRS(Qindex) = peaks(i); 
    else
        NPKI = (0.125 * signal(peaks(i))) + (0.875 * NPKI); 
    end

    Threshold = NPKI + 0.25 * (SPKI - NPKI);   
end


%Plot the ECG with uncorrected QRS peak locations
figure;
subplot(2,1,1); plot(p0); 
hold on; plot(QRS,p0(QRS), 'r*'); hold off;
title('The uncorrected QRS peak locations - unfiltered signal');

%correct index locations 
QRS = QRS-38;%There is 38 sample delays
%5 lowpass, 16 high pass, 2 derivative, 15 integral 


%fix the out of bounds issue 
if QRS(1) <= 30
    QRS = QRS(2:end);
end
if QRS(length(QRS)) >= (length(p0) - 30)
    QRS = QRS(1:end - 1);
end


%correct QRS location for sure to match the highest value in the original 
for i = 1: length(QRS)  

    QRSMaxLocation = QRS(i); 
    CurrentQRSMaxValue = p0(QRS(i)); % the value at the uncorrected QRS peak
    
    for j = QRS(i) - 30 : QRS(i) + 30
                   
        if CurrentQRSMaxValue < p0(j)           
            CurrentQRSMaxValue = p0(j); 
            QRSMaxLocation = j; 
        end    
    
    end
    
    QRS(i) = QRSMaxLocation; % Update the QRS Peak location index with the new max location    
end


 
% Plot the corrected QRS peak locations
subplot(2,1,2); plot (p0);
hold on; plot(QRS,p0(QRS), 'r*'); hold off;
title('The corrected QRS peak locations - unfiltered signal');
xlabel('Time (Sec)'); ylabel('ECG (mV)'); axis auto;

%%%%%%% Calculate R-R interval and other stuff %%%%%%%%%%%
difference  = diff(QRS,1);%take digital derivative 
time_difference  = difference*5;%each sample is 5 ms
average_R_R = mean(time_difference)
standard_deviation = std(time_difference)
number_of_beats = length(QRS)
Hear_rate = number_of_beats./t(end)*60

