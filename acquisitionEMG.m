function acquisitionEMG(numTrials, muscle)

session = input('session name: ', 's');
%% ros setup
%rosinit('localhost');
move_motor = rossvcclient('/myo_blink/move');
topic = '/myo_blink/joints/lower/angle';
muscle_sub = rossubscriber(topic);

request = rosmessage(move_motor);
request.Muscle = muscle;
request.Action = 'keep';
force = 40;
request.Setpoint = force;

setParam(loadParams());
param = getParam();

%% obtain MVC
% MVC = calculateMVC(param.channels(muscle));
% disp('Calibration completed. Starting the experiment in 10 secs.');
% pause(10);
MVC = 330.0;
%% start the experiment
f = figure();
scrsz = get(groot,'ScreenSize');
f.Position = [2000 scrsz(4) scrsz(3) scrsz(4)];

emg_array = zeros(100);
data = struct('EMG', {}, 'angle', {}, 'force', {});
i = 0;
j = 1;
while i <= numTrials
    
    %call(move_motor, request);
    tic

    %% save emg signal, time, muscle force, current angle
    while toc < 3
        [emg_msg,~] = judp('RECEIVE',16573,400);
        emg = jsondecode(char(emg_msg));
        emg_array(j) = emg(param.channels(muscle)); 
        filt_emg = filterEMG(emg_array, MVC);
        %hold on;
        plot(1:j, emg_array(1:j), '-');
        plot(1:j, filt_emg(1:j), '-');
        %plot(j, emg(1), '-x');
        j = j + 1;
        joint_msg = receive(muscle_sub);
        joint_angle = joint_msg.Data;
        data(end+1) = struct('EMG', emg, 'angle', joint_angle, 'force', request.Setpoint);
    end
    
    request.Setpoint = 38;
    %call(move_motor, request);
    i = i + 1;
    request.Setpoint = force + 5;
    pause(2);
end

save(strcat(session, '.mat'), 'data');
end


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
        [emg_msg,~] = judp('RECEIVE',16573,400);
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