local Body = require'Body'
local t_entry, t_update
local state = {}
state._NAME = ...
require'hcm'
require'gcm'
local util = require'util'

-- Neck limits
local dqNeckLimit = {45*DEG_TO_RAD,45*DEG_TO_RAD}

function state.entry()
  print(state._NAME..' Entry' ) 
  -- When entry was previously called
  local t_entry_prev = t_entry
  -- Update the time of entry
  t_entry = Body.get_time()
  t_update = t_entry
  -- Reset the human position
  hcm.set_motion_headangle(Body.get_head_position())
end

function state.update()
  -- print(_NAME..' Update' )
  -- Get the time of update
  local t = Body.get_time()
  local dt = t - t_update
  -- Save this at the last update time
  t_update = t 

  -- Grab the target
  local neckAngleTarget = hcm.get_motion_headangle()
  --print('Neck angle',unpack(neckAngleTarget))
  -- Grab where we are
  local qNeck = Body.get_head_command_position()
  local headBias = hcm.get_camera_bias()
  qNeck[1] = qNeck[1] - headBias[1]  


  -- Go!
  local qNeck_approach, doneNeck = 
    util.approachTol( qNeck, neckAngleTarget, dqNeckLimit, dt )
    
  -- Update the motors



  local headBias = hcm.get_camera_bias()

  local RAD_TO_DEG = 180/math.pi
print(string.format("Bias neck: %.2f cam pitch: %.2f roll:%.2f deg\n",
        headBias[1]*RAD_TO_DEG,headBias[2]*RAD_TO_DEG,headBias[3]*RAD_TO_DEG))

  Body.set_head_command_position({qNeck_approach[1]+headBias[1],qNeck_approach[2]})

  --5 is the idle state! 
  -- Ready, set, playing states
  if gcm.get_game_state()==1 or gcm.get_game_state()==2 and gcm.get_game_state()==3 then 
    return 'scan' 
  end

end

function state.exit()  
  print(state._NAME..' Exit' )
end

return state