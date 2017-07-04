function param = loadParams()
param.bandfilter = [10,500]; % lower and upper freq
param.lowfilter = 500;
param.highfilter = 10;
param.RMSwindow = 250;
%param.nbframe = 4000; % number frame needed (interpolation)
param.trials = 3;
param.trialDuration = 2000;
param.sampleRate = 600;
param.freq = 600;
param.mvc_duration = 1; % in seconds
param.mvc_trials = 4;
param.mvc_pause = 3; % seconds for rest between mvc trials
param.mvc_repetitions = 2;

param.t_hold_force = 8;
param.t_relax = 3;
% param.method = 'low' ; % RMS ou low
param.channels = containers.Map;
param.channels('biceps') = [1,2];
param.channels('triceps') = [5,6];
end
