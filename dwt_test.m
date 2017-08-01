param=loadParams();
samples.wrestling = {};
samples.calibration = {};
% load('00_calibration.mat')
% load('00.mat')
% load('18_leonard.mat')
% load('17_leonard_calibration.mat')
% load('15_matthias_calibration.mat')
% load('16_matthias.mat')

samples.calibration = [samples.calibration, load('19_emec_calibration.mat')];
samples.wrestling = [samples.wrestling, load('19_emec.mat')];

samples.wrestling = [samples.wrestling, load('18_leonard.mat')];
samples.calibration = [samples.calibration, load('17_leonard_calibration.mat')];


samples.wrestling = [samples.wrestling, load('17_leonard.mat')];
samples.calibration = [samples.calibration, load('17_leonard_calibration.mat')];

 
% samples.wrestling = [samples.wrestling,load('16_matthias.mat')];
% samples.calibration = [samples.calibration, load('15_matthias_calibration.mat')];
% 
%  
% samples.wrestling = [samples.wrestling, load('15_matthias.mat')];
% samples.calibration = [samples.calibration, load('15_matthias_calibration.mat')];

 
samples.wrestling = [samples.wrestling, load('20_juri.mat')];
samples.calibration = [samples.calibration, load('20_juri_calibration.mat')];

 
samples.wrestling = [samples.wrestling, load('21_juri.mat')];
samples.calibration = [samples.calibration, load('20_juri_calibration.mat')];

%  
% samples.wrestling = [samples.wrestling, load('22_julian.mat')];
% samples.calibration = [samples.calibration, load('22_julian_calibration.mat')];
% 
% samples.wrestling = [samples.wrestling, load('23_julian.mat')];
% samples.calibration = [samples.calibration, load('22_julian_calibration.mat')];

emg = nan(1,65000*8);
forces = nan(1,65000*8);

k=1;

for i=1:length(samples.calibration)
    clf;
    cur = samples.wrestling(i);
    cur_c = samples.calibration(i);
   
    nfilt_emg = cur{1}.data.subject.biceps.EMG(60000:end);
    RMS = nan(size(nfilt_emg));
    for j = param.RMSwindow:length(nfilt_emg)-param.RMSwindow-1
        RMS(j,:) = rms(nfilt_emg(j-param.RMSwindow+1:j+param.RMSwindow));
    end
    
%     RMS = RMS/max(max(RMS));
    
%     plot(RMS); hold on; 
%     mvc(1:length(RMS))=cur_c{1}.calib.calibration.triceps.MVC;
%     plot(mvc);
    
%     n = isnan(RMS);
    
    len = length(cur{1}.data.subject.biceps.EMG(60000:end));
    emg(k:len+k-1) = RMS/cur_c{1}.calib.calibration.biceps.MVC;
    forces(k:len+k-1) = cur{1}.data.robot.triceps.force(60000:end);
    k = k + len + 1;
end

clf;
del = isnan(emg);
emg(del) = [];
forces(del) = [];

plot(100*emg);hold on;
plot(forces);

dim=length(emg);
window = 200;
overlap = 0;

emg_mav = nan(1,floor(dim/(window-overlap))-1);
force_mav = nan(1,floor(dim/(window-overlap))-1);
emg_rms = nan(1,floor(dim/(window-overlap))-1);
inputs = nan(floor(dim/window),27);
outputs = nan(floor(dim/window),1);


j=1;
 
level = 3;
mother = 'db2';

% subplot(211); plot(sample); 
% title('Original signal'); 
% subplot(212); plot(ret); 
% title('Wavelet decomposition structure, level 3, db2 mother function') 
% xlabel(['Coefs for approx. at level 3 ' ... 
%         'and for det. at levels 3, 2 and 1'])
    
clf;
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
%     plot(ret);hold on;
    
    force = forces(range)';
    
    inputs(j,:) = ret;
    outputs(j,:) = mean(force);
%     inputs((j-1)*27 +1 :j*27) = ret;
%     outputs((j-1)*27 +1 :j*27) = mean(force);
    
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

% clf;
% plot(100*inputs);hold on;
% plot(outputs);

% modelfun = @(b, x) b(1)-b(1)./(1+4/b(2).*(cosh(b(3)/b(4).*x)).^2);
% modelfun=@(b,x)(1./(1+exp(-b(1).*x-b(2))));
% modelfun = @(b,x)x(:,1)/8 + b(1) - b(1)*((1 - (3/(b(1)*4))).^(x(:,1)/2));
% modelfun = @(b,x)b(1) + b(2)*x(:,1).^b(3) + b(4)*x(:,2).^b(5);

net = feedforwardnet([5,3], 'trainbfg');
% net.layers{1}.transferFcn = 'purelin';
% net.layers{2}.transferFcn = 'logsig';
[net, p] = train(net, inputs', outputs');
y = net(inputs');
perf = perform(net, y, outputs')
