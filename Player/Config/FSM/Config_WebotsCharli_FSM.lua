module(..., package.seeall);
require('vector')

--FSM parameters

--How much should we slow down all SM timings compared to real robot?
speedFactor = 1.0;

fsm={};

--Should we consider obstacle?
fsm.enable_obstacle_detection = 1;

--fsm.playMode = 1; --For Demo without orbit
--fsm.playMode = 2; --Simple Behavior with orbit
fsm.playMode = 3; --Advanced Behavior 

fsm.enable_walkkick = 0;
fsm.enable_sidekick = 0;

--------------------------------------------------
--BodyReady : make robot move to initial position
--------------------------------------------------
fsm.bodyReady={};
fsm.bodyReady.maxStep = 0.15;
fsm.bodyReady.thClose = {0.20,10*math.pi/180} --r and theta

--------------------------------------------------
--BodySearch : make robot turn to search the ball
--------------------------------------------------
fsm.bodySearch={};
fsm.bodySearch.vSpin = 0.3; --Turn velocity
fsm.bodySearch.timeout = 20.0*speedFactor;

--------------------------------------------------
--BodyChase : move the robot towards the ball
--------------------------------------------------
fsm.bodyChase={};
fsm.bodyChase.maxStep = 0.20;
fsm.bodyChase.rClose = 0.70;
fsm.bodyChase.timeout = 30.0*speedFactor;
fsm.bodyChase.tLost = 8.0*speedFactor;

--------------------------------------------------
--BodyOrbit : make the robot orbit around the ball
--------------------------------------------------
fsm.bodyOrbit={};
fsm.bodyOrbit.maxStep = 0.15;
fsm.bodyOrbit.rOrbit = 0.40;
fsm.bodyOrbit.rFar = 0.90;
fsm.bodyOrbit.thAlign = 10*math.pi/180;
fsm.bodyOrbit.timeout = 30.0 * speedFactor;
fsm.bodyOrbit.tLost = 3.0*speedFactor;

--------------------------------------------------
--BodyPosition : Advanced chase-orbit
--------------------------------------------------
fsm.bodyPosition={};
fsm.bodyPosition.maxStep = 0.20;--Normal velocity
fsm.bodyPosition.maxStep2 = 0.30;--Front dash velocity

fsm.bodyPosition.maxStep = 0.15;--Normal velocity
fsm.bodyPosition.maxStep2 = 0.20;--Front dash velocity


--Trajectory parameters
fsm.bodyPosition.rTurn = 0.50; 
fsm.bodyPosition.rDist1 = 0.80; 
fsm.bodyPosition.rDist2 = 0.40; 
fsm.bodyPosition.rTurn2 = 0.16; 
fsm.bodyPosition.rOrbit = 0.95; 

fsm.bodyPosition.rClose = 0.80; 
fsm.bodyPosition.thClose = {0.16,0.30,10*math.pi/180};
fsm.bodyPosition.tLost =  8*speedFactor; 
fsm.bodyPosition.timeout = 30*speedFactor; 

--------------------------------------------------
--BodyApproach :  Align the robot for kick
--------------------------------------------------
fsm.bodyApproach={};
fsm.bodyApproach.maxStep = 0.12; --Max walk velocity
fsm.bodyApproach.timeout = 10.0*speedFactor;
fsm.bodyApproach.rFar = 0.90; --Max ball distance
fsm.bodyApproach.tLost = 3.0*speedFactor;--ball detection timeout

--x and y target position for stationary straight kick
fsm.bodyApproach.xTarget11={0, 0.30,0.34}; --min, target, max
fsm.bodyApproach.yTarget11={0.03, 0.06, 0.09}; --min, target ,max

--x and y target position for stationary kick to left
fsm.bodyApproach.xTarget12={0, 0.25,0.30}; --min, target, max
fsm.bodyApproach.yTarget12={-0.01, 0.02, 0.05}; --min, target ,max

--x and y target position for front walkkick
fsm.bodyApproach.xTarget21={0, 0.38,0.45}; --min, target, max
fsm.bodyApproach.yTarget21={0.04, 0.055, 0.09}; --min, target ,max

--Target position for side walkkick to left
fsm.bodyApproach.xTarget22={0, 0.20,0.25}; --min, target, max
fsm.bodyApproach.yTarget22={-0.01, 0.02, 0.05}; --min, target ,max

--------------------------------------------------
--BodyKick : Stationary Kick
--------------------------------------------------
fsm.bodyKick={};

--initial wait 
fsm.bodyKick.tStartWait = 0.5;
fsm.bodyKick.tStartWaitMax = 1.0;
fsm.bodyKick.thGyroMag = 100; 

--ball position checking params
fsm.bodyKick.kickTargetFront = {0.30,0.06};

--For kicking to the left
fsm.bodyKick.kickTargetSide = {0.30,0.01};

fsm.bodyKick.kickTh = {0.06,0.05};

--delay for camera following the ball
fsm.bodyKick.tFollowDelay = 2.2; 

--------------------------------------------------
--BodyWalkKick : Dynamic Kick
--------------------------------------------------
fsm.bodyWalkKick={};
fsm.bodyWalkKick.timeout = 2.0*speedFactor; 
--------------------------------------------------
--BodyGotoCenter : Going to center when ball is lost
--------------------------------------------------
fsm.bodyGotoCenter={};
fsm.bodyGotoCenter.maxStep=0.20;
fsm.bodyGotoCenter.rClose=0.60;
fsm.bodyGotoCenter.timeout=20.0*speedFactor;




--------------------------------------------------
--HeadTrack : Track the ball
--------------------------------------------------
fsm.headTrack = {};
fsm.headTrack.timeout = 2.0 * speedFactor;
fsm.headTrack.tLost = 1.5 * speedFactor;
fsm.headTrack.minDist = 0.30; --If ball is closer than this, don't look up
fsm.headTrack.fixTh={0.20,0.08}; --Fix yaw axis if ball is within this box

--------------------------------------------------
--HeadReady : Track the horizonal line for localization
--------------------------------------------------
fsm.headReady={}
fsm.headReady.dist = 3.0; 
fsm.headReady.height = 1.0; 
fsm.headReady.tScan= 5.0*speedFactor; 

--------------------------------------------------
--HeadReadyLookGoal : Look Goal during bodyReady
--------------------------------------------------
fsm.headReadyLookGoal={}
fsm.headReadyLookGoal.timeout = 1.5 * speedFactor;

--------------------------------------------------
--HeadScan: Scan around for ball
--------------------------------------------------
fsm.headScan={};
fsm.headScan.pitch0 = 45*math.pi/180;
fsm.headScan.pitchMag = 25*math.pi/180;
fsm.headScan.yawMag = 90*math.pi/180;
fsm.headScan.pitchTurn0 = 45*math.pi/180;
fsm.headScan.pitchTurnMag = 45*math.pi/180;
fsm.headScan.yawMagTurn = 45*math.pi/180;
fsm.headScan.tScan = 3.0*speedFactor;

--------------------------------------------------
--HeadKick: Fix headangle for approaching
--------------------------------------------------
fsm.headKick={};
fsm.headKick.pitch0=50*math.pi/180;
fsm.headKick.xMax = 0.60;
fsm.headKick.yMax = 0.14;
fsm.headKick.tLost = 3.0*speedFactor;
fsm.headKick.timeout = 3.0*speedFactor;

--------------------------------------------------
--HeadKickFollow: Follow ball after kick
--------------------------------------------------
fsm.headKickFollow={};
fsm.headKickFollow.pitch={50*math.pi/180, 0*math.pi/180};
fsm.headKickFollow.pitchSide = 30*math.pi/180;
fsm.headKickFollow.yawMagSide = 90*math.pi/180;
fsm.headKickFollow.tFollow = 1.0*speedFactor;

--------------------------------------------------
--HeadLookGoal: Look up to see the goal
--------------------------------------------------
fsm.headLookGoal={};
fsm.headLookGoal.yawSweep = 50*math.pi/180;
fsm.headLookGoal.tScan = 1.0*speedFactor;

--------------------------------------------------
--HeadSweep: Look around to find the goal
--------------------------------------------------
fsm.headSweep={};
fsm.headSweep.tScan=1.0*speedFactor;
