function acquisitionEMG(muscle)

%% ros setup
if not(robotics.ros.internal.Global.isNodeActive)
    rosinit('localhost');
end

%% load params 
if not(exist('param', 'var'))
    setParam(loadParams());
    param = getParam();
end

%%
move_motor = rossvcclient('/myo_blink/move');

request = rosmessage(move_motor);
request.Muscle = muscle;
request.Action = 'keep';
min = 40;
max = 60;
forces = (max-min).*rand(param.trials+1,1) + min;
request.Setpoint = min;

%% load params 
if not(exist('param', 'var'))
    setParam(loadParams());
    param = getParam();
end

input('Press ENTER to move the robot', 's');

%% alternate force on the muscle
i = 1;
while i <= param.trials
  
    disp('Wrestle');
    call(move_motor, request);
    pause(param.t_hold_force);    
    request.Setpoint = 38;
    call(move_motor, request);
    i = i + 1;
    request.Setpoint = forces(i);% + i*5;
    disp(forces(i));
    disp('Relax');
    pause(param.t_relax);
end


end



