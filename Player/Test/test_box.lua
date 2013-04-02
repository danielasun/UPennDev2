module(... or '', package.seeall)
dofile('load_paths.lua'); -- Test files must look back to main player directory

require('Config')
require('vector')
require('mcm')
require('Speak')
require('Body')
require('Motion')

-- For motion capture
require 'primecm'
primecm.set_skeleton_enabled(0);
require 'libboxer'

darwin = false;
-- Enable OP specific 
if(Config.platform.name == 'OP') then
  darwin = true;
  --SJ: OP specific initialization posing (to prevent twisting)
  Body.set_body_hardness(0.3);
  Body.set_actuator_command(Config.sit.initangle);
  unix.usleep(1E6*1.0);
  Body.set_body_hardness(0);
end

--This is robot specific 
init = false;
calibrating = false;
ready = false;
if( webots or darwin) then
  ready = true;
end


smindex = 0;
initToggle = true;

targetvel=vector.zeros(3);

if( webots ) then
  controller.wb_robot_keyboard_enable( 100 );
end
function process_keyinput()

  local byte = get_key_byte();
  if byte~=0 then
    --    print('byte: ', byte)
    --    print('string: ',string.char(byte))
    -- Walk velocity setting
    if byte==string.byte("i") then	targetvel[1]=targetvel[1]+0.02;
    elseif byte==string.byte("j") then	targetvel[3]=targetvel[3]+0.1;
    elseif byte==string.byte("k") then	targetvel[1],targetvel[2],targetvel[3]=0,0,0;
    elseif byte==string.byte("l") then	targetvel[3]=targetvel[3]-0.1;
    elseif byte==string.byte(",") then	targetvel[1]=targetvel[1]-0.02;
    elseif byte==string.byte("h") then	targetvel[2]=targetvel[2]+0.02;
    elseif byte==string.byte(";") then	targetvel[2]=targetvel[2]-0.02;

      -- Stance commands
    elseif byte==string.byte("q") then	
      walk.switch_stance(1);
    elseif byte==string.byte("w") then	
      walk.switch_stance(0);
    elseif byte==string.byte("e") then	
      walk.switch_stance(2);

      -- Punch commands
    elseif byte==string.byte("a") then
      walk.doPunch(1);
    elseif byte==string.byte("s") then
      walk.doPunch(2); 
    elseif byte==string.byte("d") then
      walk.doPunch(3); 

      -- walk commands
    elseif byte==string.byte("7") then	
      Motion.event("sit");
    elseif byte==string.byte("8") then	
      if walk.active then 
        walk.stopAlign();
      end
      Motion.event("standup");
    elseif byte==string.byte("9") then	
      Motion.event("walk");
      walk.start();
    end
    walk.set_velocity(unpack(targetvel));

    --    print("Command velocity:",unpack(walk.velCommand))
  end
end

function update()
  count = count + 1;

  if (not init)  then
    if (calibrating) then
      if (Body.calibrate(count)) then
        Speak.talk('Calibration done');
        calibrating = false;
        ready = true;
      end

    elseif (ready) then
      init = true;
    else
      if (count % 20 == 0) then
        if (Body.get_change_state() == 1) then
          Speak.talk('Calibrating');
          calibrating = true;
        end
      end

      -- toggle state indicator
      if (count % 100 == 0) then
        initToggle = not initToggle;
        if (initToggle) then
          Body.set_indicator_state({1,1,1}); 
        else
          Body.set_indicator_state({0,0,0});
        end
      end
    end

  else
    -- update state machines 
    Motion.update();
    Body.update();
  end

  local dcount = 50;
  if (count % 50 == 0) then
    --    print('fps: '..(50 / (unix.time() - tUpdate)));
    tUpdate = unix.time();
    -- update battery indicator
    Body.set_indicator_batteryLevel(Body.get_battery_level());
  end

  -- check if the last update completed without errors
  lcount = lcount + 1;
  if (count ~= lcount) then
    print('count: '..count)
    print('lcount: '..lcount)
    Speak.talk('missed cycle');
    lcount = count;
  end
end

-- Initialize
Motion.entry()
count = 0;
lcount = 0;
tUpdate = unix.time();
Motion.event("standup");

-- if using Webots simulator just run update
local tDelay = 0.005 * 1E6; -- Loop every 5ms
if ( webots or darwin ) then
  while (true) do

    -- Listen to keyboard
    process_keyinput();
    -- If skeleton is available:
    if( primecm.get_skeleton_enabled()) then
      local arms = libboxer.get_arm_angles();
      left_arm = arms[1] or left_arm_old or {0,0,0};
      right_arm = arms[2] or right_arm_old or {0,0,0};
      left_arm_old = left_arm or left_arm_old or {0,0,0};
      right_arm_old = right_arm or right_arm_old or {0,0,0};

      local rpy = libboxer.get_torso_orientation() or vector.new({0,0,0});
      --print(string.format('RPY: %.1f %.1f %.1f\n',unpack(180/math.pi*rpy)))
      walk.upper_body_override(left_arm,right_arm,rpy)
    else
      walk.upper_body_override_off();
    end
    update();
    io.stdout:flush();
    if(darwin) then
      -- TODO: Update Team
      unix.usleep(tDelay);
    end
  end
end

