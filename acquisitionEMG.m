function acquisitionEMG()

muscles = [string('biceps'), string('triceps')];
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

request.Action = 'keep';
min = 40;
max = 65;
forces = (max-min).*rand(2*param.trials+1,1) + min;
request.Setpoint = min;

%% load params 
if not(exist('param', 'var'))
    setParam(loadParams());
    param = getParam();
end

input('Press ENTER to move the robot', 's');

%% alternate force on the muscle
i = 1;
while i <= param.trials*2
    if mod(i,2)==0
        muscle = 'biceps'
    else
        muscle = 'triceps'
    end
    request.Muscle = muscle;
    disp(forces(i));
    request.Setpoint = forces(i);
    disp('Wrestle');
    call(move_motor, request);
    pause(param.t_hold_force);    
    request.Setpoint = 38;
    call(move_motor, request);
    i = i + 1;
    disp('Relax');
    pause(param.t_relax);
end


end



