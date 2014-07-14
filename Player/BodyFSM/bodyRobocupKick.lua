local state = {}
state._NAME = ...
local Body   = require'Body'
local util   = require'util'
local vector = require'vector'
local libStep = require'libStep'
-- FSM coordination
local simple_ipc = require'simple_ipc'
local motion_ch = simple_ipc.new_publisher('MotionFSM!')


-- Get the human guided approach
require'hcm'
-- Get the robot guided approach
require'wcm'

require'mcm'

local kick_started

function state.entry()
  print(state._NAME..' Entry' )
  -- Update the time of entry
  local t_entry_prev = t_entry -- When entry was previously called
  t_entry = Body.get_time()
  t_update = t_entry
  mcm.set_walk_stoprequest(1)
  kick_started = false
  mcm.set_walk_kickphase(0)
  mcm.set_walk_stoprequest(1)


  mcm.set_walk_kicktype(1)
end

function state.update()
  if Config.disable_kick then

    local ballx = wcm.get_ball_x() - Config.fsm.bodyRobocupApproach.target[1]
    local bally = wcm.get_ball_y()
    local ballr = math.sqrt(ballx*ballx+bally*bally)
    if ballr > 0.6 then
      return 'done'
    end
    return
  end

  local t  = Body.get_time()
  local dt = t - t_update
  -- Save this at the last update time
  t_update = t

  if mcm.get_walk_kickphase()==0 then    
    if mcm.get_walk_ismoving()==0 then
      mcm.set_walk_steprequest(1)
      mcm.set_walk_kickphase(1)
    end
  elseif mcm.get_walk_kickphase()==2 then
    print("bodykick done!")
    if mcm.get_walk_kicktype()==1 then
      return 'testdone' --this means testing mode (don't run body fsm)      
    else
      return 'done'
    end
  end 
end

function state.exit()
  print(state._NAME..' Exit' )
  mcm.set_walk_kickphase(0) --now can kick again
end

return state
