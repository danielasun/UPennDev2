module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('util')
require('Config')
<<<<<<< HEAD

=======
require('postDist')
>>>>>>> NaoDev
require('wcm')

t0 = 0;
timeout = 10.0;

-- maximum walk velocity
maxStep = 0.04;

-- ball detection timeout
tLost = 3.0;

-- kick target threshold
xKick = 0.18;
xTarget = 0.15;
	
print('xKick')
print(xKick)

yKickMin = 0.02;
yKickMax = 0.06;

-- maximum ball distance threshold
rFar = 0.45;

-- alignment
thAlign = 15.0*math.pi/180.0;

function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();
end

function update()
  local t = Body.get_time();

  -- get ball position
  ball = wcm.get_ball();
  ballR = math.sqrt(ball.x^2 + ball.y^2);
  --print('ball: '..ball.x..', '..ball.y);
  --print('ballR '..ballR);

<<<<<<< HEAD
  -- get attack goalpost positions and goal angle
  posts = {wcm.get_goal_attack_post1(), wcm.get_goal_attack_post2()}

  -- calculate the relative distance to each post, find closest
  pose = wcm.get_pose();
  p1Relative = util.pose_relative({posts[1][1], posts[1][2], 0}, {pose.x, pose.y, pose.a});
  p2Relative = util.pose_relative({posts[2][1], posts[2][2], 0}, {pose.x, pose.y, pose.a});
  p1Dist = math.sqrt(p1Relative[1]^2 + p1Relative[2]^2);
  p2Dist = math.sqrt(p2Relative[1]^2 + p2Relative[2]^2);
  pClosest = math.min(p1Dist, p2Dist);
  pFarthest = math.max(p1Dist, p2Dist);

=======
>>>>>>> NaoDev
  -- calculate walk velocity based on ball position
  vStep = vector.new({0,0,0});
  vStep[1] = .5*(ball.x - xTarget);
  vStep[2] = .75*(ball.y - util.sign(ball.y)*0.05); --.75
  scale = math.min(maxStep/math.sqrt(vStep[1]^2+vStep[2]^2), 1);
  vStep = scale*vStep;

  ballA = math.atan2(ball.y - math.max(math.min(ball.y, 0.05), -0.05), math.max(ball.x+0.10, 0.10));
  vStep[3] = 0.5*ballA;
<<<<<<< HEAD
  walk.set_velocity(vStep[1],vStep[2],vStep[3]);

  attackBearing, daPost = wcm.get_attack_bearing();
  --print(vStep[1]..','..vStep[2]..','..vStep[3]);

=======
  --Player FSM, turn towards the goal
    attackBearing, daPost = wcm.get_attack_bearing();
    kick_angle=wcm.get_kick_angle();
    targetangle = util.mod_angle(attackBearing-kick_angle);
    if targetangle > 10*math.pi/180 then
      vStep[3]=0.2;
    elseif targetangle < -10*math.pi/180 then
      vStep[3]=-0.2;
    else
      vStep[3]=0;
    end
  --print(vStep[1]..','..vStep[2]..','..vStep[3]);

  --when the ball is on the side of the ROBOT, backstep a bit
  local wAngle = math.atan2 (ball.y,ball.x);
  if math.abs(wAngle) > 45*math.pi/180 then
    vStep[1]=vStep[1] - 0.03;
    print('backstep');
  else
    --Otherwise, don't make robot backstep
    vStep[1]=math.max(0,vStep[1]);
  end

  walk.set_velocity(vStep[1],vStep[2],vStep[3]);

>>>>>>> NaoDev
  if (t - ball.t > tLost) then
    print('ballLost');
    return "ballLost";
  end
  if (t - t0 > timeout) then
    print('timeout');
    return "timeout";
  end
  if (ballR > rFar) then
    print('ballFar');
    return "ballFar";
  end
<<<<<<< HEAD
  if (math.abs(attackBearing) > thAlign) then
=======
  if ((math.abs(attackBearing) > thAlign) and postDist.kick()) then
>>>>>>> NaoDev
    print('ballAlign');
    return 'ballAlign';
  end
  if ((ball.x < xKick) and (math.abs(ball.y) < yKickMax) and
      (math.abs(ball.y) > yKickMin)) then
<<<<<<< HEAD
    if ((pClosest > pNear) and (pClosest < pFar)) then
      print('kick');   
      return "kick";
    else
      print("My distance is ",pClosest,"\n");
      return "walkKick";
    end
=======
    if(postDist.kick()) then
      return "kick"
    else
      return "walkKick"
    end  
>>>>>>> NaoDev
  end
end

function exit()
end

