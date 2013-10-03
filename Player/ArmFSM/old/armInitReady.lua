--------------------------------
-- Humanoid arm state
-- (c) 2013 Stephen McGill, Seung-Joon Yi
--------------------------------
local state = {}
state._NAME = ...

local Body   = require'Body'
local util   = require'util'
local vector = require'vector'

local t_entry, t_update, t_finish
local timeout = 15.0

-- Goal position is arm Init, with hands in front, ready to manipulate
local qL_desired = Config.arm.qLArmInit[2]
local qR_desired = Config.arm.qRArmInit[2]

-- Angular velocity limit
local dqArmMax = Config.arm.slow_elbow_limit

function state.entry()
  print(state._NAME..' Entry' )
  -- Update the time of entry
  local t_entry_prev = t_entry -- When entry was previously called
  t_entry = Body.get_time()
  t_update = t_entry
  t_finish = t

  -- Where are the arms right now?
  local qLArm = Body.get_larm_command_position()
  local qRArm = Body.get_rarm_command_position()
  Body.set_larm_command_position(qLArm)
  Body.set_rarm_command_position(qRArm)

end

function state.update()
--  print(state._NAME..' Update' )
  -- Get the time of update
  local t  = Body.get_time()
  local dt = t - t_update
  -- Save this at the last update time
  t_update = t
  --if t-t_entry > timeout then return'timeout' end

  -- Get the current joint positions (via commands)
  local qLArm = Body.get_larm_command_position()
  local qRArm = Body.get_rarm_command_position()

  -- Go to the allowable position
  local qL_approach, doneL
  qL_approach, doneL = util.approachTol( qLArm, qL_desired, dqArmMax, dt )
  Body.set_larm_command_position( qL_approach )
  
  local qR_approach, doneR
  qR_approach, doneR = util.approachTol( qRArm, qR_desired, dqArmMax, dt )
  Body.set_rarm_command_position( qR_approach )

  -- We are done when we are within tolerance
  if doneR and doneR then return 'done' end

end

function state.exit()
  print(state._NAME..' Exit' )
end

-- Add Epi-sate
state.epi = {}
-- Is this going going in forward to Ready, or reverse to Init?
state.epi.reverse = false

return state