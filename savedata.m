function [emg_array, forces, joint_angles] = savedata(muscle)

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
emg_array = zeros(1,dim);
joint_angles = nan(1,dim);
forces = nan(1,dim);

%%
jtopic = '/myo_blink/joints/lower/angle';
mtopic = strcat('/myo_blink/muscles/', muscle, '/sensors');
joint_sub = rossubscriber(jtopic);
muscle_sub = rossubscriber(mtopic);

%% obtain MVC
MVC = calculateMVC(param.channels(muscle));
disp('Calibration completed. Starting the experiment in 10 secs.');
pause(5);
disp('Starting the experiment');
pause(5);
% MVC = 330.0;

%%
for j=1:length(emg_array)
    [emg_msg,~] = judp('RECEIVE',16571,400);
    emg = jsondecode(char(emg_msg));
    emg_array(j) = emg(param.channels('biceps'));
    %plot(1:j, emg_array(1:j), '-');
    joint_msg = joint_sub.LatestMessage;
    joint_angles(j) = joint_msg.Data;
    forces(j) = muscle_sub.LatestMessage.ElasticDisplacement * 0.2 + 38;
end

disp('saving data..');
%%
data = struct('MVC', MVC, 'EMG', emg_array, 'angle', joint_angles, 'force', forces);
save(strcat(session, '.mat'), 'data');

end