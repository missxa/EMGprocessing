global arr
arr = ...
 [0.9 1.5 13.8 19.8 24.1 28.2 35.2 60.3 74.6 81.3];
ydata = ...
 [455.2 428.6 124.1 67.3 43.2 28.1 13.1 -0.4 -1.3 -1.5];


% fun = @(x)x(1)*exp(x(2)*xdata(end-1))-ydata;
x0 = [100,-1];
% x0(2) = [100,-1];
% x0(3) = [100,-1];
% x0(4) = [100,-1]

% func = @(x)e(x,t);
syms t e

fun = @(x)symsum(e(x,t,arr) - x*e(x,t-1,arr) - x*e(x,t-2,arr) - ydata(t), t, 5, 7);

x = lsqnonlin(fun, x0, [], [])
