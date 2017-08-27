param=loadParams();

[emg,activation] = loadData([17:20]);

for i=1:2
    emg(i,:) = (emg(i,:) - mean(emg(i,:)))/std(emg(i,:));
end;
% emg = emg(2,:);

% plot(emg);hold on;
% plot(activation);

dim=length(emg);
Fs = 599;
window = 150;
overlap = 0;

inputs = nan(floor(dim/window),2);
outputs = nan(floor(dim/window),1);


j=1;
 
level = 3;
mother = 'db4';

% subplot(211); plot(sample); 
% title('Original signal'); 
% subplot(212); plot(ret); 
% title('Wavelet decomposition structure, level 3, db2 mother function') 
% xlabel(['Coefs for approx. at level 3 ' ... 
%         'and for det. at levels 3, 2 and 1'])
    
clf;
for i=window:window:dim
    range = i-window+1:i;
    sample = emg(:,range); 
    
    [C1 , L1] = wavedec(sample(1,:) , level , mother);
%     cA3 = appcoef(C , L , mother, level);
    d31 = detcoef(C1,L1,level);
    
    [C2 , L2] = wavedec(sample(2,:) , level , mother);
    d32 = detcoef(C2,L2,level);
%     r = cA3;
%     rMinMax = minmax(r);
%     s = sample;
%     sMinMax = minmax(sample);
%     ret = (((r - rMinMax(1)) / (rMinMax(2) - rMinMax(1))) * (sMinMax(2) - sMinMax(1))) + sMinMax(1); 
%     plot(ret);hold on;
    
    a = activation(range)';
    
    inputs(j,2) = var(abs(d32));%mean(d3);
    inputs(j,1) = mean(abs(d32));
%     inputs(j,2) = std(d3);
    outputs(j) = mean(a);
    
    j=j+1;
end

% outputs = downsample(activation,window);
% outputs(end) = [];
for i=1:2
    inputs(i,:) = lpfilter(inputs(i,:), 10, Fs/window);
end
% corrcoef(inputs,outputs)

% clf;
% plot(100*inputs);hold on;
% plot(outputs);

% modelfun = @(b, x) b(1)-b(1)./(1+4/b(2).*(cosh(b(3)/b(4).*x)).^2);
% modelfun=@(b,x)(1./(1+exp(-b(1).*x-b(2))));
% modelfun = @(b,x)x(:,1)/8 + b(1) - b(1)*((1 - (3/(b(1)*4))).^(x(:,1)/2));
% modelfun = @(b,x)b(1) + b(2)*x(:,1).^b(3) + b(4)*x(:,2).^b(5);

in = inputs';
out = outputs';
net = feedforwardnet([10]);
% net.layers{end}.transferFcn = 'tansig';
net.trainParam.epochs = 30000;
ing = nndata2gpu(in);
outg = nndata2gpu(out);
net = configure(net,in,out);
[net, p] = train(net, ing, outg,'useParallel', 'yes', 'useGPU','yes','showResources','yes');


% testing
[emg,activation] = loadData([21]);
dim=length(emg);
Fs = 599;
window = 150;

inputs = nan(floor(dim/window),2);
outputs = nan(floor(dim/window),1);

for i=1:2
    emg(i,:) = (emg(i,:) - mean(emg(i,:)))/std(emg(i,:));
end;

j=1;

for i=window:window:dim
    range = i-window+1:i;
    sample = emg(:,range); 
    
    [C1 , L1] = wavedec(sample(1,:) , level , mother);
%     cA3 = appcoef(C , L , mother, level);
    d31 = detcoef(C1,L1,level);
    
    [C2 , L2] = wavedec(sample(2,:) , level , mother);
    d32 = detcoef(C2,L2,level);
    
    a = activation(range)';
    
    inputs(j,2) = var(abs(d32));%mean(d3);
    inputs(j,1) = mean(abs(d32));
%     inputs(j,2) = std(d3);
    outputs(j) = mean(a);
    
    j=j+1;
end

for i=1:2
    inputs(i,:) = lpfilter(inputs(i,:), 10, Fs/window);
end

test_outputs = sim(net, inputs');
clf;
plot(test_outputs)
hold on;plot(outputs)



