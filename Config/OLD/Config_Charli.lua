module(..., package.seeall);
local util = require('util')
local vector = require('vector')
local parse_hostname = require('parse_hostname')

platform = {}; 
platform.name = 'Charli'

params = {}
params.name = {"Robot", "Walk", "World", "Kick", "Vision", "FSM", "Camera"};
params.Camera_Platform = "OP"
params.Camera = "Grasp"

util.LoadConfig(params, platform)

-- Device Interface Libraries
dev = {};
dev.body = 'CharliBody'; 
dev.camera = 'OPCam';
dev.kinematics = 'CharliKinematics';
dev.ip_wired = '192.168.123.255';
dev.ip_wired_port = 111111;
dev.ip_wireless = '192.168.1.255';
dev.ip_wireless_port = 54321;
dev.game_control='OPGameControl';
dev.team='TeamNSL';
dev.walk='BasicWalk';  --should be updated
--dev.walk='NewNewNewNewWalk';
dev.kick = 'NewNewKick'

speak = {}
speak.enable = false; 

-- Game Parameters
game = {};
game.teamNumber = 30;
--Not a very clean implementation but we're using this way for now
local robotName=unix.gethostname();
--Default role: 0 for goalie, 1 for attacker, 2 for defender
--Default team: 0 for blue, 1 for red
game.playerID = 1; --for scarface
game.role = 1; --Default attacker
game.teamColor = 1; --Red team
game.robotName = robotName;
game.robotID = game.playerID;
game.nPlayers = 2;
--------------------

--FSM and behavior settings
fsm.game = 'RoboCup';
fsm.head = {'GeneralPlayer'};
fsm.body = {'GeneralPlayer'};

--Behavior flags, should be defined in FSM Configs but can be overrided here
fsm.enable_obstacle_detection = 1;
fsm.kickoff_wait_enable = 0;
--fsm.playMode = 3; --1 for demo, 2 for orbit, 3 for direct approach
--fsm.enable_walkkick = 1;
--fsm.enable_sidekick = 1;

fsm.playMode = 3; --1 for demo, 2 for orbit, 3 for direct approach
fsm.enable_walkkick = 0;
fsm.enable_sidekick = 0;

--FAST APPROACH TEST
fsm.fast_approach = 1;
--fsm.bodyApproach.maxStep = 0.06;

-- Team Parameters
team = {};
team.msgTimeout = 5.0;
team.nonAttackerPenalty = 6.0; -- eta sec
team.nonDefenderPenalty = 0.5; -- dist from goal

-- keyframe files
km = {};
km.standup_front = 'km_NSLOP_StandupFromFront.lua';
km.standup_back = 'km_NSLOP_StandupFromBack.lua';

-- Low battery level
-- Need to implement this api better...
bat_low = 100; -- 10V warning

gps_only = 0;

--Speak enable
speakenable = false;

--Use soft-landing foot trajectory
walk.use_alternative_trajectory = 1;
walk.use_alternative_trajectory = 0;