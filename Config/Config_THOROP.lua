Config = {}

------------------------
-- General parameters --
------------------------
Config.PLATFORM_NAME = 'THOROP'
Config.nJoint = 35
-- Dummy arms are the two MX-106R motors per arm
Config.USE_DUMMY_ARMS = false

-----------------------
-- Device Interfaces --
-----------------------
Config.dev = {
	body         = 'THOROPBody',
	game_control = 'OPGameControl',
	team         = 'TeamNSL',
	kick         = 'NewNewKick',
	walk         = 'HumbleWalk',
	crawl        = 'ScrambleCrawl',
	largestep    = 'ZMPStepStair',
	gender       = 'boy',
}

-- Printing of debug messages
Config.debug = {
	webots_wizard=false,	
  -- obstacle = true,
  follow = false,	
  --approach = true,
  --planning = true,
  --goalpost = true,
}

Config.use_angle_localization = true
Config.demo = false
--Config.demo = true
Config.use_localhost = false
--Config.disable_kick = true
Config.disable_kick = false


-- Monitor and logging
Config.enable_monitor = true
Config.enable_log = false
Config.use_log = false

if IS_WEBOTS then
  Config.USE_DUMMY_ARMS = false
  Config.use_gps_pose = false
--  Config.use_gps_pose = true
  
  Config.use_localhost = true
  Config.use_walkkick = true
  --Config.use_walkkick = false
  --Config.backward_approach = true
end

Config.default_role = 2 --0 goalie / 1 attacker / 2 tester
Config.default_state = 5 -- 0 1 2 3 4 for init~finished, 5 for untorqued, 6 for testing

---------------------------
-- Complementary Configs --
---------------------------

--SJ: Now we choose the which config to load here
local exo = {
  'Robot',
  'Walk',
  'Net',
  'Manipulation',
  'FSM',
  --'FSM_RoboCup',
  --'FSM_DRCTrials',
  'World',
  'Vision'
}

-- Load each exogenous Config file
for _,v in ipairs(exo) do
	--[[
  --local fname = {HOME, '/Config/Config_', Config.PLATFORM_NAME, '_', v, '.lua'}
  local fname = {'Config/Config_', Config.PLATFORM_NAME, '_', v, '.lua'}
  dofile(table.concat(fname))
	--]]
	----[[
	local fname = {Config.PLATFORM_NAME,'/Config_', Config.PLATFORM_NAME, '_', v}  
  require(table.concat(fname))
	--]]
end

--Vision parameter hack (robot losing ball in webots)
if IS_WEBOTS then
  Config.vision.ball.th_min_fill_rate = 0.25 
  Config.fsm.headLookGoal.yawSweep = 30*math.pi/180
  Config.fsm.headLookGoal.tScan = 2.0

  Config.fsm.bodyRobocupFollow.circleR = 1
  Config.fsm.bodyRobocupFollow.kickoffset = 0.5

  Config.fsm.bodyRobocupApproach.target={0.25,0.12}  
  Config.fsm.bodyRobocupApproach.th = {0.01, 0.01}
  Config.world.use_imu_yaw = true


  Config.walk.velLimitX = {-.10,.10} 
  Config.walk.velLimitX = {-.10,.15} 
  Config.walk.velLimitY = {-.04,.04}
  Config.walk.velDelta  = {0.04,0.02,0.1}

  Config.stop_after_score = false
--  Config.stop_after_score = true

--  Config.auto_state_advance = true
  --Config.auto_state_advance = false
end

Config.stop_at_neutral = true --false for walk testing

--Config.fsm.headTrack.timeout = 6  --ORG value
Config.fsm.headTrack.timeout = 3  
Config.fsm.dqNeckLimit ={40*DEG_TO_RAD, 180*DEG_TO_RAD}

Config.approachTargetX = {
	0.45, --for kick 0 (walkkick)
	0.28, --for kick 1 (st kick)
	0.35  --for kick 2 (weak walkkick)
}

if IS_WEBOTS then 
	Config.approachTargetX = {
    0.35, --for kick 0 (walkkick)
    0.30, --for kick 1 (st kick)
    0.35  --for kick 2 (weak walkkick)
  }
end

--  Config.approachTargetY= {-0.07,0.05}  --L/R aiming offsets
Config.approachTargetY= {-0.07,0.02}  --L/R aiming offsets

Config.ballX_threshold1 = -1.5 --The threshold we use walkkick
Config.ballX_threshold2 = 0.5 --The threshold we start using strong kick

--  Config.use_walkkick = true
Config.use_walkkick = false

--Config.torque_legs = false
Config.torque_legs = true
Config.enable_obstacle_scan = true
Config.disable_goal_vision = false

--  Config.auto_state_advance = true
Config.auto_state_advance = false

Config.enable_single_goalpost_detection = false
Config.enable_single_goalpost_detection = true

-- Config.enable_weaker_kick = true

Config.use_walkkick = true
--  Config.use_walkkick = false

Config.disable_ball_when_lookup = true

Config.maxStepApproachTh = 0.30
Config.maxStepApproach1 = 0.10
Config.maxStepApproach2 = 0.06

Config.supportY_preview = -0.02
Config.supportY_preview2 = -0.01

--Config.enable_goalie_legspread = true --NOT WORKING FOR NOW
--Config.enable_goalie_legspread = false
--Config.goalie_turn_to_ball = true

---------------------------------------------------------------
--Semi-final config end
---------------------------------------------------------------


Config.goalieBallX_th = -0.5
Config.goalie_odometry_only = true
Config.goaliePosX = 0.40
Config.ballYFactor = 1.4
Config.gamecontroller_detect = true
Config.gamecontroller_timeout = 5.0


Config.max_goalie_y = 0.7
---------------------------------------------------
-- testing

Config.goalie_threshold_x = 0.10
Config.goalie_t_startmove = 10.0


Config.assume_goalie_blocking = true
Config.enemy_goalie_shift_factor = 0.15
return Config
