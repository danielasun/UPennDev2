--------------------------------
-- Humanoid arm state
-- (c) 2013 Stephen McGill, Seung-Joon Yi
--------------------------------


--Armdrive: rotate left wrist roll joint to target angle

local state = {}
state._NAME = ...

local Body   = require'Body'
local util   = require'util'
local vector = require'vector'
local movearm = require'movearm'
local t_entry, t_update, t_finish
local timeout = 15.0

-- Goal position is arm Init, with hands in front, ready to manipulate

local qLArm0,qRArm0



function state.entry()
  print(state._NAME..' Entry' )
  -- Update the time of entry
  local t_entry_prev = t_entry -- When entry was previously called
  t_entry = Body.get_time()
  t_update = t_entry
  t_finish = t

  stage = 1

  qLArm0 = Body.get_larm_command_position()
  qRArm0 = Body.get_rarm_command_position()

  local pg = 4
  local tg = 16
  for i=1,10 do
    Body.set_rarm_position_p({pg,pg,pg,pg,pg,pg,tg})
    unix.usleep(1e6*0.01);

    Body.set_larm_position_p({pg,pg,pg,pg,pg,pg,pg})
    unix.usleep(1e6*0.01);
  end

end

function state.update()
  local t  = Body.get_time()
  local dt = t - t_update
  -- Save this at the last update time
  t_update = t
--  print(state._NAME..' Update' )

  wheel_angle = hcm.get_drive_wheel_angle()
  local qRArm1 = {
    qRArm0[1],qRArm0[2],qRArm0[3],
    qRArm0[4],qRArm0[5],qRArm0[6],
    qRArm0[7]+wheel_angle,
  }
  
  local ret = movearm.setArmJoints(qLArm0,qRArm1,dt)  
end

function state.exit()
  
  print(state._NAME..' Exit' )
end

return state
