function [emg_array] = savedata()

session = input('session name: ', 's');
data.subject.name = input('name: ', 's');
data.subject.age = input('age: ', 's');
data.subject.height = input('height: ', 's');
data.subject.weight = input('weight: ', 's');

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
muscles = [string('biceps'), string('triceps')];
dim = param.sampleRate * (2 * param.trials * (param.t_hold_force + param.t_relax));
data.robot.joint_angles = nan(1,dim);

for i=1:length(muscles)
    emg_array.(muscles{i}) = nan(1,dim);
    emg_array.(muscles{i}) = nan(1,dim);
    data.robot.(muscles{i}).force = nan(1,dim);
    data.robot.(muscles{i}).l_CE = nan(1,dim);
    data.robot.(muscles{i}).delta_l_SEE = nan(1,dim);
    data.robot.(muscles{i}).dot_l_CE = nan(1,dim);
    data.robot.(muscles{i}).dot_l_SEE = nan(1,dim);
    subscriber.(muscles{i}) = rossubscriber( strcat('/myo_blink/muscles/', muscles{i}, '/sensors'));
end

%%
jtopic = '/myo_blink/joints/lower/angle';
joint_sub = rossubscriber(jtopic);

%% obtain MVC
[calibration.biceps.MVC, calibration.biceps.EMG] = calculateMVC('biceps');
[calibration.triceps.MVC, calibration.triceps.EMG] = calculateMVC('triceps');

calib = struct('calibration', calibration);
save(strcat(session, '_calibration_', '.mat'), 'calib');
input('Calibration completed. Pres ENTER to continue the experiment', 's');

%%
for j=1:dim
    try
        [emg_msg,~] = judp('RECEIVE',16571,400);
        emg = jsondecode(char(emg_msg));
    catch
        warning('Corrupted data, skipping the message');
        input('Communication problem. Press ENTER to continue: ', 's');
        continue;
    end
    
    for i=1:length(muscles)
        ch = param.channels('biceps');
        emg_array.(muscles{i})(j) = emg(ch(2)) -  emg(ch(1));
        msg = subscriber.(muscles{i}).LatestMessage;
        data.robot.(muscles{i}).force(j) = msg.ElasticDisplacement * 0.2 + 38;
        % raw values of the robot state, no conversion
        data.robot.(muscles{i}).l_CE(j) = msg.ContractileDisplacement;% * 0.006 * pi / 6.28319;
        data.robot.(muscles{i}).delta_l_SEE(j) = msg.ElasticDisplacement;
        data.robot.(muscles{i}).dot_l_CE(j) = msg.ActuatorVel;
        data.robot.(muscles{i}).dot_l_SEE(j) = msg.ElasticVel;
    end
    
    data.robot.joint_angles(j) = joint_sub.LatestMessage.Data;    
end

%% apply basic filters 
disp('preprocessing data..');
clear emg
fields = fieldnames(emg_array);
for i = 1:numel(fields)
    emg = emg_array.(fields{i});
    % band-pass
    bfilt_emg =  bandfilter(emg',param.bandfilter(1),param.bandfilter(2),param.freq);
    % notch (50 Hz) 
    data.subject.(fields{i}).EMG = notch(bfilt_emg, param.sampleRate, 50);
end
%%
save(strcat(session, '.mat'), 'data');
end