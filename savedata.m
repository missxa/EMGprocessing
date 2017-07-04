function [emg_array, forces, joint_angles] = savedata()

session = input('session name: ', 's');
%% ros setup
if not(robotics.ros.internal.Global.isNodeActive)
    rosinit('localhost');
end

%% load params 
if not(exist('param', 'var'))
    setParam(loadParams());
    param = getParam();
end

%% allocate space 
dim = param.sampleRate * (param.trials * (param.t_hold_force + param.t_relax));
emg_array.biceps = zeros(1,dim);
emg_array.triceps = zeros(1,dim);
joint_angles = nan(1,dim);
forces.biceps = nan(1,dim);
forces.triceps = nan(1,dim);

%%
jtopic = '/myo_blink/joints/lower/angle';
joint_sub = rossubscriber(jtopic);

btopic = strcat('/myo_blink/muscles/', 'biceps', '/sensors');
ttopic = strcat('/myo_blink/muscles/', 'triceps', '/sensors');

b_sub = rossubscriber(btopic);
t_sub = rossubscriber(btopic);

bch = param.channels('biceps');
tch = param.channels('triceps');

%% obtain MVC
[calibration.biceps.MVC, calibration.biceps.EMG] = calculateMVC('biceps');
[calibration.triceps.MVC, calibration.triceps.EMG] = calculateMVC('triceps');

calib = struct('calibration', calibration);
save(strcat(session, '_calibration_', '.mat'), 'calib');
input('Calibration completed. Pres ENTER to continue the experiment', 's');

%%
for j=1:dim
    [emg_msg,~] = judp('RECEIVE',16571,400);
    emg = jsondecode(char(emg_msg));
    emg_array.biceps(j) = emg(bch(2)) - emg(bch(1));
    emg_array.triceps(j) = emg(tch(2)) - emg(tch(1));
    %plot(1:j, emg_array(1:j), '-');
    joint_msg = joint_sub.LatestMessage;
    joint_angles(j) = joint_msg.Data;
    forces.biceps(j) = t_sub.LatestMessage.ElasticDisplacement * 0.2 + 38;
    forces.triceps(j) = b_sub.LatestMessage.ElasticDisplacement * 0.2 + 38;
    
end

%% apply basic filters 
disp('preprocessing data..');
clear emg
fields = fieldnames(emg_array)
for i = 1:numel(fields)
    emg = emg_array.(fields{i});
    % band-pass
    bfilt_emg =  bandfilter(emg',param.bandfilter(1),param.bandfilter(2),param.freq);
    % notch (50 Hz) 
    data.(fields{i}).EMG = notch(bfilt_emg, param.sampleRate, 50);
end
%%
% data.biceps.EMG = biceps_emg_array;
data.biceps.force = forces.biceps;
% data.triceps.EMG =  triceps_emg_array;
data.triceps.force = forces.triceps;

save(strcat(session, '.mat'), 'data');
end