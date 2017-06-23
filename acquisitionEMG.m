function acquisitionEMG(muscle)

%% ros setup
if not(robotics.ros.internal.Global.isNodeActive)
    rosinit('localhost');
end

move_motor = rossvcclient('/myo_blink/move');

request = rosmessage(move_motor);
request.Muscle = muscle;
request.Action = 'keep';
force = 40;
request.Setpoint = force;

%% load params 
if not(exist('param', 'var'))
    setParam(loadParams());
    param = getParam();
end

i = 1;
%% alternate force on the muscle
while i <= param.trials
  
    call(move_motor, request);
    disp('Wrestle');
    pause(param.t_hold_force);    
    request.Setpoint = 38;
    call(move_motor, request);
    i = i + 1;
    request.Setpoint = force + 5;
    disp('Relax');
    pause(param.t_relax);
end


end



