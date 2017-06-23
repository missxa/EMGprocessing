function [filt_emg] = filterEMG(emg,MVC)
param = getParam;

% 1) Rebase
reb_emg = emg - mean(emg);

% 2) band-pass filter
bfilt_emg =  bandfilter(reb_emg,param.bandfilter(1),param.bandfilter(2),param.freq);

%) 3) signal rectification
rect_emg = abs(bfilt_emg);

% 4) low pass filter at 5Hz
lfilt_emg = lpfilter(rect_emg, param.lowfilter, param.freq);

if isnan(MVC)
    % 5) RMS
    RMS = nan(size(lfilt_emg));
    for j = param.RMSwindow:length(lfilt_emg)-param.RMSwindow-1
        RMS(j,:) = rms(lfilt_emg(j-param.RMSwindow+1:j+param.RMSwindow,:));
    end
    filt_emg = RMS;
else
    % 5) Normalization
    filt_emg = lfilt_emg ./ (MVC*0.8/100);
    
end
end