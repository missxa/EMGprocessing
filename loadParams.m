function param = loadParams()
param.bandfilter = [20,500]; % lower and upper freq
param.lowfilter = 5;
param.RMSwindow = 10;
%param.nbframe = 4000; % number frame needed (interpolation)
param.trials = 15;
param.trialDuration = 2000;
param.sampleRate = 256;
param.freq = 256;
param.mvc_duration = 3; % in seconds
param.mvc_trials = 3;
param.mvc_pause = 5; % seconds for rest between mvc trials
% param.method = 'low' ; % RMS ou low
param.channels = containers.Map;
param.channels('biceps') = 1;
param.channels('triceps') = 5;
end
