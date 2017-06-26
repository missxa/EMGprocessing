function [MVC] = calculateMVC(channel)
param = getParam();
emg = zeros(param.sampleRate*(param.mvc_duration*param.mvc_trials));
f = figure();
% scrsz = get(groot,'ScreenSize');
% f.Position = [2000 scrsz(4) scrsz(3) scrsz(4)];

i = 1;
for j = 1:param.mvc_trials
    disp('Flex the muscle as strong as possible');
    tic
    while toc < param.mvc_duration% + param.mvc_pause
        [emg_msg,~] = judp('RECEIVE',16571,400);
        emg_array = jsondecode(char(emg_msg));
        emg(i) = emg_array(channel);
        i = i + 1;
    end
    disp('Relax');
    pause(param.mvc_pause);
end

RMS = filterEMG(emg, nan);

plot(1:length(emg), emg);
hold on;
plot(1:length(RMS), RMS);

MVC = max(max(RMS));

end

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

function r = getParam
global param
r = param;
end

function setParam(val)
global param
param = val;
end