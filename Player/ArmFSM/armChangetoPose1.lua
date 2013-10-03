--------------------------------
-- Humanoid arm state
-- (c) 2013 Stephen McGill, Seung-Joon Yi
--------------------------------
local state = {}
state._NAME = ...

local Body   = require'Body'
local util   = require'util'
local vector = require'vector'
local movearm = require'movearm'
local t_entry, t_update, t_finish
local timeout = 15.0

-- Goal position is arm Init, with hands in front, ready to manipulate

local qL_desired = {}
local qR_desired = {}


-- Angular velocity limit
local dqArmMax = Config.arm.slow_elbow_limit

local move_stage=1
qLOrg = Config.arm.qLArmInit[1]



--IK based home position

local lShoulderYawTarget = -5*Body.DEG_TO_RAD
local rShoulderYawTarget = 5*Body.DEG_TO_RAD
local pLWristTarget = {-.0,.30,-.24,0,0,0}
local pRWristTarget = {-.0,-.30,-.24,0,0,0}


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
  
  if qLArm[4]<-50*Body.DEG_TO_RAD and qRArm[4]<-50*Body.DEG_TO_RAD then
    --Elbow bent: backward motion
    print("REV")
    total_stage = 2
    qL_desired = {Config.arm.qLArmInit[2], Config.arm.qLArmInit[1]}
    qR_desired = {Config.arm.qRArmInit[2], Config.arm.qRArmInit[1]}    
  else
    --Elbow stretched: forward motion
    total_stage = 1
    qL_desired = {Config.arm.qLArmInit[1]}
    qR_desired = {Config.arm.qRArmInit[1]}    
  end
  move_stage = 1

  stage = 1
end

function state.update()
  local t  = Body.get_time()
  local dt = t - t_update
  -- Save this at the last update time
  t_update = t
--  print(state._NAME..' Update' )
  -- Get the time of update  

 --[[ 
  if movearm.setArmJoints(qL_desired[move_stage],qR_desired[move_stage],
      dt, dqArmMax)==1 then
    move_stage = move_stage+1;  
  end  
  if move_stage>total_stage then
    return "done";  
  end
--]]



--Wrist IK based movement
  local qLArm = Body.get_larm_command_position()
  local qRArm = Body.get_rarm_command_position()
  if stage==1 then   --Straighten wrist    
    ret = movearm.setArmJoints(
      {qLArm[1],qLArm[2],qLArm[3],qLArm[4],0,0,0},
      {qRArm[1],qRArm[2],qRArm[3],qRArm[4],0,0,0},
      dt)
    if ret==1 then stage = stage + 1 end
  elseif stage==2 then --Move arms to the sides            
    ret = movearm.setWristPosition(
      pLWristTarget, pRWristTarget,dt, lShoulderYawTarget,rShoulderYawTarget)
    if ret==1 then return"done";
    end
  end
--



end

function state.exit()

  local qLArm = Body.get_larm_command_position()
  trWrist = Body.get_forward_lwrist(qLArm)
  print("LWrist pos:",unpack(trWrist))
  

  print(state._NAME..' Exit' )
end

-- Add Epi-sate
state.epi = {}
-- Is this going going in forward to Ready, or reverse to Init?
state.epi.reverse = false

return state