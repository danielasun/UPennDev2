module(..., package.seeall);

require('parse_hostname')
require('vector')
require('os')

platform = {};
platform.name = 'WebotsNao'

function loadconfig(configName)
  local localConfig=require(configName);
  for k,v in pairs(localConfig) do
    Config[k]=localConfig[k];
  end
end

loadconfig('World/Config_Nao_World')
loadconfig('Walk/Config_WebotsNao_Walk')
loadconfig('Kick/Config_WebotsNao_Kick')
loadconfig('Vision/Config_WebotsNao_Vision')

--Location Specific Camera Parameters--
loadconfig('Vision/Config_WebotsNao_Camera')

-- Device Interface Libraries
dev = {};
dev.body = 'NaoWebotsBody'; 
dev.camera = 'NaoWebotsCam';
dev.kinematics = 'NaoWebotsKinematics';
dev.game_control = 'WebotsNaoGameControl';
dev.team= 'TeamSPL';
--dev.walk = 'NaoWalk';
--dev.kick = 'NaoKick';
dev.walk = 'NewWalk';
dev.kick = 'NewKick';

dev.walk = 'NewNewWalk';

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
fsm.game = 'RoboCup';
if (game.playerID == 1) then
  fsm.body = {'NaoGoalie'};
  fsm.head = {'NaoGoalie'};
else
  fsm.body = {'NaoPlayer'};
  fsm.head = {'NaoPlayer'};
end

fsm.body = {'OpPlayerNSL'};

-- Team Parameters

team = {};
team.msgTimeout = 5.0;
team.nonAttackerPenalty = 6.0; -- eta sec
team.nonDefenderPenalty = 0.5; -- dist from goal


--Head Parameters

head = {};
head.camOffsetZ = 0.41;
head.pitchMin = -35*math.pi/180;
head.pitchMax = 30*math.pi/180;
head.yawMin = -120*math.pi/180;
head.yawMax = 120*math.pi/180;
head.cameraPos = {{0.05390, 0.0, 0.06790},
                  {0.04880, 0.0, 0.02381}}; 
head.cameraAngle = {{0.0, 0.0, 0.0},
                    {0.0, 40*math.pi/180, 0.0}};
head.neckZ=0.14; --From CoM to neck joint
head.neckX=0;  


-- keyframe files

km = {};
km.kick_right = 'km_WebotsNao_KickForwardRight.lua';
km.kick_left = 'km_WebotsNao_KickForwardLeft.lua';
km.standup_front = 'km_WebotsNao_StandupFromFront.lua';
km.standup_back = 'km_WebotsNao_StandupFromBack.lua';


-- sitting parameters

sit = {};
sit.bodyHeight = 0.225;
sit.supportX = 0;
sit.dpLimit = vector.new({.1,.01,.03,.1,.3,.1});

-- standing parameters

stance = {};
stance.dpLimit = vector.new({.04, .03, .04, .05, .4, .1});
stance.delay = 80; --amount of time to stand still after standing to regain balance.

-- enable obstacle detection
BodyFSM = {}
BodyFSM.enable_obstacle_detection = 1;

--Skip all checks in vision for 160*120 image 
webots_vision = 1; 

speedFactor = 1.0; 
