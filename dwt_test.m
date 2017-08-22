param=loadParams();

[emg,activation] = loadData();
emg = emg(1,:);

% plot(emg);hold on;
% plot(activation);

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
    d3 = detcoef(C,L,3);
    r = cA3;
    rMinMax = minmax(r);
    s = sample;
    sMinMax = minmax(sample);
    ret = (((r - rMinMax(1)) / (rMinMax(2) - rMinMax(1))) * (sMinMax(2) - sMinMax(1))) + sMinMax(1); 
%     plot(ret);hold on;
    
    a = activation(range)';
    
    inputs(j,:) = ret;%mean(d3);
%     inputs(j,2) = std(d3);
    outputs(j,:) = mean(a);
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

net = feedforwardnet([10], 'trainbfg');
% net.layers{1}.transferFcn = 'purelin';
% net.layers{end}.transferFcn = 'logsig';
[net, p] = train(net,inputs', outputs');
y = net(inputs');
perf = perform(net, y, outputs')
