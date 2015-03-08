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


local step_planner
local t_entry, t_update, t_exit
local nwaypoints, wp_id
local waypoints = {}

local target_pose
local uLeft_now, uRight_now, uTorso_now, uLeft_next, uRight_next, uTorso_next
local supportLeg
local ball_side = 1

local last_ph = 0

local uTorso0 = nil
local pose0 = nil

local last_step = 0

local uLeftGlobalTarget, uRightGlobalTarget


local function step_approach(uLeftGlobalTarget, uRightGlobalTarget)

  local uLeft = mcm.get_status_uLeft()
  local uRight = mcm.get_status_uRight()
  local uTorso = mcm.get_status_uTorso()
  local supportLeg = mcm.get_status_supportLeg()
  local uTorsoNext

  local uLSupport = util.pose_global({Config.walk.supportX, Config.walk.supportY,0},uLeft)
  local uRSupport = util.pose_global({Config.walk.supportX, -Config.walk.supportY,0},uRight)
  local uTorsoCurrent = util.se2_interpolate(0.5, uLSupport, uRSupport)

  local pose = wcm.get_robot_pose()

  --uLeft and uRight from uTorso0
  local uLeftFromTorso = util.pose_relative(uLeft,uTorsoCurrent)
  local uRightFromTorso = util.pose_relative(uRight,uTorsoCurrent)

  local uLeftTargetFromTorso = util.pose_relative(uLeftGlobalTarget,pose)
  local uRightTargetFromTorso = util.pose_relative(uRightGlobalTarget,pose)


  local uTargetCenter = util.se2_interpolate(0.5,uLeftTargetFromTorso,uRightTargetFromTorso)
  uTargetCenter = util.pose_global({-0.15,0,0},uTargetCenter)

  dist=math.sqrt(uTargetCenter[1]*uTargetCenter[1]+uTargetCenter[2]*uTargetCenter[2])

  local angleMove=0


  local vStepTarget

--  if dist > 0.30 then --robot away from traget, aim for the center position
  if false then    
    local angleTurn
    angleTurn = math.atan2(uTargetCenter[2],uTargetCenter[1])
    if dist>0.50 then 
      vStepTarget={uTargetCenter[1],uTargetCenter[2],angleTurn}
    else
      vStepTarget={uTargetCenter[1],uTargetCenter[2],uTargetCenter[3]}
    end


  else  
    local supportStr 
    if last_step==1 then
      if supportLeg==0 then 
        uRightTargetFromTorso = util.pose_global({0, -2*Config.walk.footY,0},uLeftFromTorso)
        uLSupportNext = util.pose_global({Config.walk.supportX, Config.walk.supportY,0},uLeftFromTorso)
        uRSupportNext = util.pose_global({Config.walk.supportX, -Config.walk.supportY,0},uRightTargetFromTorso)
        uTorsoNext = util.se2_interpolate(0.5, uLSupportNext, uRSupportNext)
      else
        uLeftTargetFromTorso = util.pose_global({0, 2*Config.walk.footY,0},uRightFromTorso)
        uLSupportNext = util.pose_global({Config.walk.supportX, Config.walk.supportY,0},uLeftFromTorso)
        uRSupportNext = util.pose_global({Config.walk.supportX, -Config.walk.supportY,0},uRightTargetFromTorso)
        uTorsoNext = util.se2_interpolate(0.5, uLSupportNext, uRSupportNext)
      end
      local vStep = {uTorsoNext[1],uTorsoNext[2],0}    
      last_step=2
      return vStep,false
    elseif last_step==2 then
      return {0,0,0},true      
    end

    if supportLeg==0 then 
      --Last step was left support step (right foot movement)
      --Next step should be left foot movement
      supportStr='Left foot move next'
      uLSupportNext = util.pose_global({Config.walk.supportX, Config.walk.supportY,0},uLeftFromTorso)
      uRSupportNext = util.pose_global({Config.walk.supportX, -Config.walk.supportY,0},uRightTargetFromTorso)
      uTorsoNext = util.se2_interpolate(0.5, uLSupportNext, uRSupportNext)
      angleMove = util.mod_angle(uLSupportNext[3]-uLeft[3])
    else
      supportStr='Right foot move next'
      uLSupportNext = util.pose_global({Config.walk.supportX, Config.walk.supportY,0},uLeftFromTorso)
      uRSupportNext = util.pose_global({Config.walk.supportX, -Config.walk.supportY,0},uRightTargetFromTorso)
      uTorsoNext = util.se2_interpolate(0.5, uLSupportNext, uRSupportNext)
      angleMove = util.mod_angle(uRSupportNext[3]-uRight[3])
    end
    vStepTarget = {uTorsoNext[1],uTorsoNext[2],uTorsoNext[3]}
  end
  
  --local vStepTarget = {uTorsoNext[1],uTorsoNext[2],0}
  

  local maxStep = 0.06
  if Config.maxStepApproach1 then
    if vStepTarget[1]>(Config.maxStepApproachTh or 0.20) then
      maxStep = Config.maxStepApproach1 or 0.10
    else
      maxStep = Config.maxStepApproach2 or 0.06
    end
  end


  vStep={0,0,0}
  vStep[1] = math.min(Config.walk.velLimitX[2],math.max(Config.walk.velLimitX[1],vStepTarget[1]))
  vStep[2] = math.min(Config.walk.velLimitY[2],math.max(Config.walk.velLimitY[1],vStepTarget[2]))
  vStep[3] = math.min(Config.walk.velLimitA[2],math.max(Config.walk.velLimitA[1],vStepTarget[3]))

  velMag = math.sqrt(vStep[1]^2+vStep[2]^2)
  vStep[1]=vStep[1]/velMag * math.min(maxStep,velMag)
  vStep[2]=vStep[2]/velMag * math.min(maxStep,velMag)
  --vStep[3]=0
  vStep[3]=vStep[3]*0.3

  if Config.debug.approach then
    print("=====\n"..supportStr)
    print(string.format("Ball xy: %.2f %.2f",wcm.get_ball_x(),wcm.get_ball_y() ))
    print(string.format("Current: L (%.2f %.2f)  T (%.2f, %.2f)R (%.2f %.2f)",
      uLeftFromTorso[1],uLeftFromTorso[2],
      0,0,      
      uRightFromTorso[1],uRightFromTorso[2]))
    print(string.format("Target:  L (%.2f %.2f)  T (%.2f %.2f) R (%.2f %.2f)",
      uLeftTargetFromTorso[1],uLeftTargetFromTorso[2],
      uTorsoNext[1],uTorsoNext[2],
      uRightTargetFromTorso[1],uRightTargetFromTorso[2]))
  end


--TODOTODOTODO
angleMove=0



  if math.abs(vStep[1]-vStepTarget[1])<0.005 and
    math.abs(vStep[2]-vStepTarget[2])<0.005 and
    math.abs(angleMove)<Config.walk.velLimitA[2] 
    then
    last_step = 1    
  end
  return vStep,false
end



local function update_target()
--[[  

  local pose = wcm.get_robot_pose()
  local pose_0 = {0,0,0}
--  print("pose:",pose[1],pose[2])

  local ballx, bally = 0,0 --This should be the relative position of the blocks
  local approachTargetX, approachTargetY = 0.03,0

  

  uLeftGlobalTarget = util.pose_global({
    ballx - approachTargetX - Config.walk.supportX,
    bally + approachTargetY + Config.walk.footY,
    0},pose_0)
  uRightGlobalTarget = util.pose_global({
    ballx - approachTargetX - Config.walk.supportX,
    bally + approachTargetY- Config.walk.footY,
    0},pose_0)
--]]

--Stationary target case
  local target_dist = 0.0
  uLeftGlobalTarget = util.pose_global({-target_dist,Config.walk.footY,0},wcm.get_step_pose() )
  uRightGlobalTarget = util.pose_global({-target_dist,-Config.walk.footY,0},wcm.get_step_pose() )
end


local finished=false

local function update_velocity()
  update_target()
  local vStep,arrived = step_approach(uLeftGlobalTarget, uRightGlobalTarget)
  mcm.set_walk_vel(vStep)
  if arrived then    
    mcm.set_walk_stoprequest(1)
    finished=true
    return 'done'
  end
end




function state.entry()
  print(state._NAME..' Entry' )
  -- Update the time of entry
  local t_entry_prev = t_entry -- When entry was previously called
  local ret = nil

  t_entry = Body.get_time()
  t_update = t_entry
  
  last_ph = 0  
  last_step = 0
  wcm.set_robot_etastep(-1) --we're in approach
  finished=false
  
  local move_target = hcm.get_move_target()
  if move_target[1]==0 and move_target[2]==0 and move_target[3]==0 then
    finished = true --don't need to walk, just exit
  else
    local pose = wcm.get_robot_pose()
    local global_target_pose = util.pose_global(move_target,pose)
    wcm.set_step_pose(global_target_pose)
    motion_ch:send'hybridwalk'    
  end
end

function state.update()  
  if finished then
    if mcm.get_walk_ismoving()==0 then 
      print("APPROACHEND")
      return "done" end
    return
  end
  --print(state._NAME..' Update' )
  -- Get the time of update
  local ret = nil
  local t  = Body.get_time()
  local dt = t - t_update
  -- Save this at the last update time
  t_update = t

  local check_ph = 0.95
  local ph = mcm.get_status_ph()
  if last_ph<check_ph and ph>=check_ph then update_velocity() end
  last_ph = ph  
end

function state.exit()
  print(state._NAME..' Exit' )
  wcm.set_robot_etastep(0) --out of approach
end

return state