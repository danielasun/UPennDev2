module(..., package.seeall);

require('parse_hostname')
require('vector')
require('os')

platform = {};
platform.name = 'WebotsCharli'

function loadconfig(configName)
  local localConfig=require(configName);
  for k,v in pairs(localConfig) do
    Config[k]=localConfig[k];
  end
end

loadconfig('Walk/Config_WebotsCharli_Walk')
loadconfig('Kick/Config_WebotsCharli_Kick')
loadconfig('World/Config_Charli_World')
loadconfig('Vision/Config_WebotsCharli_Vision')

--Location Specific Camera Parameters--
loadconfig('Vision/Config_WebotsOP_Camera')
--loadconfig('Vision/Config_WebotsCharli_Camera') --high-res

-- Device Interface Libraries
dev = {};
dev.body = 'WebotsCharliBody'; 
dev.camera = 'WebotsOPCam';
dev.kinematics = 'CharliKinematics';
dev.game_control='WebotsOPGameControl';
dev.team='TeamNull';
--dev.walk = 'NewNewWalk';
dev.walk = 'NewWalk';
dev.kick = 'NewKick';

-- Game Parameters
game = {};
game.teamNumber = (os.getenv('TEAM_ID') or 0) + 0;
-- webots player ids begin at 0 but we use 1 as the first id
game.playerID = (os.getenv('PLAYER_ID') or 0) + 1;
game.robotID = game.playerID;
game.teamColor = 1;
game.nPlayers = 4;

-- FSM Parameters
fsm = {};

loadconfig('FSM/Config_WebotsCharli_FSM')

fsm.game = 'RoboCup';
fsm.body = {'GeneralPlayer'};
fsm.head = {'GeneralPlayer'}; 

-- Team Parameters

team = {};
team.msgTimeout = 5.0;
team.nonAttackerPenalty = 6.0; -- eta sec
team.nonDefenderPenalty = 0.5; -- dist from goal

--Head Parameters
head = {};
head.camOffsetZ = 0.41;
head.pitchMin = -35*math.pi/180;
head.pitchMax = 68*math.pi/180;
head.yawMin = -120*math.pi/180;
head.yawMax = 120*math.pi/180;
head.cameraPos = {{0.05, 0.0, 0.05}} --OP, spec value, may need to be recalibrated
head.cameraAngle = {{0.0, 0.0, 0.0}}; --Default value for production OP
head.neckZ=0.42; --From CoM to neck joint , CHARLI
head.neckX=0.0; --From CoM to neck joint , CHARLI

-- keyframe files
km = {};
km.standup_front = 'km_Charli_StandupFromFront.lua';
km.standup_back = 'km_Charli_StandupFromBack.lua';

-- sitting parameters
sit = {};
sit.bodyHeight=0.40; --For Hubo
sit.supportX = 0;
sit.dpLimit = vector.new({.1,.01,.03,.1,.3,.1})*2;

-- standing parameters

stance = {};
--stance.dpLimit = vector.new({.04, .03, .04, .05, .4, .1});
stance.dpLimit = vector.new({.4, .3, .4, .05, .4, .1})*0.6;
stance.delay = 80; --amount of time to stand still after standing to regain balance.

-- enable obstacle detection
BodyFSM = {}
BodyFSM.enable_obstacle_detection = 1;
