param=loadParams();
load('00.mat');
% load('06_bernhard_calibration_.mat')
% MVC = calib.calibration.biceps.MVC;
emg = data.subject.biceps.EMG(40000:end);
forces = data.robot.triceps.force(40000:end);


% 
% emg = interp(emg,2)'; % fixes sampling rate issue for now!
% forces = interp(forces,2)';

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

plot(inputs);hold on;
plot(outputs);

% for i=0:floor(dim/(window-overlap))-1
%     range = i*(window - overlap) +1 : i*(window - overlap) + window;
%     sample = emg(range); 
% %     rms_sample = RMS(range);
%     force = forces(range)';
% 
%     [C,L] = wavedec(sample,4,mother);
%     Cnew = C;
%     tmp = cumsum(L);
%     Cnew(1:tmp(1)) = 0;
%     Cnew(tmp(end-3)+1:tmp(end-1)) = 0;   
%     Rec_signal=waverec(Cnew,L,mother); 
%     reconstructed_emg = [reconstructed_emg, Rec_signal];
%     [d1,d2,d3,d4] = detcoef(C,L,[1 2 3 4]);
%     a2 = appcoef(C,L,mother,2);
%     
% %     emg_rms(j) = mean(rms_sample);
%     emg_mav(j) = meanabs(d3);
%     force_mav(j) = mean(force);
%     j=j+1;
% end

% plot(forces,'k');hold on;
% plot(reconstructed_emg,'r','linewidth',2);hold on;
% plot(reconstructed_emg, forces);

emg_mav(isnan(emg_mav)) = [];
force_mav(isnan(emg_mav)) = [];
emg_rms(isnan(emg_rms)) = [];

% X = emg_mav;
% y = force_mav;
% plot(X, y, 'r.')

dim = 1:j-1;
plot(dim, emg_mav, dim, force_mav);

