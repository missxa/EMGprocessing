param=loadParams();
load('00_calibration.mat')
load('00.mat')
% load('10_chris_g.mat');
% load('10_chris_g_calibration_.mat');
% load('06_bernhard_calibration_.mat')
% MVC = calib.calibration.biceps.MVC;
emg = data.subject.biceps.EMG(40000:end)/calib.calibration.biceps.MVC;
forces = data.robot.triceps.force(40000:end);


% 
emg = interp(emg,2)'; % fixes sampling rate issue for now!
forces = interp(forces,2)';

dim = 1:length(emg);
% newemg = nan(1,length(emg));

% RMS = nan(size(emg));
% for j = param.RMSwindow:length(emg)-param.RMSwindow-1
%     RMS(j,:) = rms(emg(j-param.RMSwindow+1:j+param.RMSwindow));
% end


% window = 200;
% x = data.subject.biceps.EMG(21113-window/2:21113+window/2);
% y = data.subject.biceps.EMG(51950-window/2:51950+window/2);

% subplot(2,1,1)
% plot(x); title('Original Signal');
% subplot(2,1,2)
% plot(a3); title('Level-4 Approximation Coefficients');

dim=length(emg);
window = 200;
overlap = 0;

emg_mav = nan(1,floor(dim/(window-overlap))-1);
force_mav = nan(1,floor(dim/(window-overlap))-1);
emg_rms = nan(1,floor(dim/(window-overlap))-1);
inputs = nan(1,floor(dim/window)*27);
outputs = nan(1,floor(dim/window)*27);

reconstructed_emg = [];

j=1;
 
level = 3;
mother = 'db2';

% subplot(211); plot(sample); 
% title('Original signal'); 
% subplot(212); plot(ret); 
% title('Wavelet decomposition structure, level 3, db2 mother function') 
% xlabel(['Coefs for approx. at level 3 ' ... 
%         'and for det. at levels 3, 2 and 1'])
    
for i=window:window:dim
    range = i-window+1:i;
    sample = emg(range); 
    
    [C , L] = wavedec(sample , level , mother);
    cA3 = appcoef(C , L , mother, level);
    r = cA3;
    rMinMax = minmax(r);
    s = sample;
    sMinMax = minmax(sample);
    ret = (((r - rMinMax(1)) / (rMinMax(2) - rMinMax(1))) * (sMinMax(2) - sMinMax(1))) + sMinMax(1); 
    plot(ret);hold on;
    
    force = forces(range)';
    inputs((j-1)*27 +1 :j*27) = ret;
    outputs((j-1)*27 +1 :j*27) = mean(force);
    
%     subplot(211); plot(sample); 
%     title('Original signal'); 
%     subplot(212); plot(ret); 
%     title('Wavelet decomposition structure, level 3, db2 mother function') 
%     xlabel(['Coefs for approx. at level 3 ' ... 
%             'and for det. at levels 3, 2 and 1'])
    
%     inputs = [inputs,ret];
%     outputs = [outputs,mean(force)];
    
    j=j+1;
end

plot(100*inputs);hold on;
plot(outputs);

% modelfun = @(b, x) b(1)-b(1)./(1+4/b(2).*(cosh(b(3)/b(4).*x)).^2);
% modelfun=@(b,x)(1./(1+exp(-b(1).*x-b(2))));
% modelfun = @(b,x)x(:,1)/8 + b(1) - b(1)*((1 - (3/(b(1)*4))).^(x(:,1)/2));
% modelfun = @(b,x)b(1) + b(2)*x(:,1).^b(3) + b(4)*x(:,2).^b(5);

net = feedforwardnet([10,10]);
net.layers{1}.transferFcn = 'logsig'
net.layers{2}.transferFcn = 'logsig'
net = train(net, inputs, outputs);
y = net(inputs);
perf = perform(net, y, outputs)
