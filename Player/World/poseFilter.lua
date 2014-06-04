local poseFilter = {}

local vector = require'vector'
local util = require 'util'
require'vcm'

N = Config.world.nParticle
xBoundary = Config.world.xBoundary
yBoundary = Config.world.yBoundary
xMax = Config.world.xMax
yMax = Config.world.yMax

goalWidth = Config.world.goalWidth
goalUpper = Config.world.goalUpper
goalLower = Config.world.goalLower
postAll = {goalUpper[1], goalUpper[2], goalLower[1], goalLower[2]}
postLeft = vector.new({goalUpper[1], goalLower[1]})
postRight = vector.new({goalUpper[2], goalLower[2]})

landmarkYellow = Config.world.landmarkYellow
landmarkCyan = Config.world.landmarkCyan
-- spot = Config.world.spot
Lcorner = Config.world.Lcorner

--Triangulation method selection
use_new_goalposts= Config.world.use_new_goalposts or 0


rGoalFilter = Config.world.rGoalFilter
aGoalFilter = Config.world.aGoalFilter
rPostFilter = Config.world.rPostFilter
aPostFilter = Config.world.aPostFilter
--TODO: remove unnecessary stuff
rKnownGoalFilter = Config.world.rKnownGoalFilter or Config.world.rGoalFilter
aKnownGoalFilter = Config.world.aKnownGoalFilter or Config.world.aGoalFilter
rKnownPostFilter = Config.world.rKnownPostFilter or Config.world.rPostFilter
aKnownPostFilter = Config.world.aKnownPostFilter or Config.world.aPostFilter
rUnknownGoalFilter = Config.world.rUnknownGoalFilter or Config.world.rGoalFilter
aUnknownGoalFilter = Config.world.aUnknownGoalFilter or Config.world.aGoalFilter
rUnknownPostFilter = Config.world.rUnknownPostFilter or Config.world.rPostFilter
aUnknownPostFilter = Config.world.aUnknownPostFilter or Config.world.aPostFilter

rLandmarkFilter = Config.world.rLandmarkFilter
aLandmarkFilter = Config.world.aLandmarkFilter

rCornerFilter = Config.world.rCornerFilter
aCornerFilter = Config.world.aCornerFilter



xp = .5*xMax*vector.new(util.randn(N)) -- x coordinate of each particle
yp = .5*yMax*vector.new(util.randn(N)) -- y coordinate
ap = 2*math.pi*vector.new(util.randu(N)) -- angle
wp = vector.zeros(N) -- weight



---Initializes a gaussian distribution of particles centered at p0
--@param p0 center of distribution
--@param dp scales how wide the distrubution is
function poseFilter.initialize(p0, dp)
  p0 = p0 or {0, 0, 0}
  dp = dp or {.5*xMax, .5*yMax, 2*math.pi}

  -- TODO: why -0.5 upon a standard normal distribution?
  -- xp = p0[1]*vector.ones(N) + dp[1]*(vector.new(util.randn(N))-0.5*vector.ones(N))
  -- yp = p0[2]*vector.ones(N) + dp[2]*(vector.new(util.randn(N))-0.5*vector.ones(N))
  xp = p0[1]*vector.ones(N) + dp[1]*vector.new(util.randn(N))
  yp = p0[2]*vector.ones(N) + dp[2]*vector.new(util.randn(N))
  ap = p0[3]*vector.ones(N) + dp[3]*(vector.new(util.randu(N))-0.5*vector.ones(N))
  wp = vector.zeros(N)
end

function poseFilter.initialize_manual_placement(p0, dp)
  p0 = p0 or {0, 0, 0}
  dp = dp or {.5*xBoundary, .5*yBoundary, 2*math.pi}

  print('re-init partcles for manual placement')
  ap = math.atan2(wcm.get_goal_attack()[2],wcm.get_goal_attack()[1])*vector.ones(N)
  xp = wcm.get_goal_defend()[1]/2*vector.ones(N)
  yp = p0[2]*vector.ones(N) + dp[2]*(vector.new(util.randn(N))-0.5*vector.ones(N))
  wp = vector.zeros(N)
end

-- TODO:
function poseFilter.initialize_unified(p0,p1,dp)
  --Particle initialization for the same-colored goalpost
  --Half of the particles at p0
  --Half of the particles at p1
  p0 = p0 or {0, 0, 0}
  p1 = p1 or {0, 0, 0}
  --Low spread  
  dp = dp or {.15*xMax, .15*yMax, math.pi/6}

  for i=1,N/2 do
    -- TODO: uniform rather than normal distribution?
    xp[i]=p0[1]+dp[1]*(math.random()-.5) 
    yp[i]=p0[2]+dp[2]*(math.random()-.5)
    ap[i]=p0[3]+dp[3]*(math.random()-.5)

    xp[i+N/2]=p1[1]+dp[1]*(math.random()-.5)
    yp[i+N/2]=p1[2]+dp[2]*(math.random()-.5)
    ap[i+N/2]=p1[3]+dp[3]*(math.random()-.5)
  end
  wp = vector.zeros(N)
end


---Sets headings of all particles to random angles with 0 weight
--@usage For when robot falls down
function poseFilter.reset_heading()
  ap = 2*math.pi*vector.new(util.randu(N))
  wp = vector.zeros(N)
end

---Returns best pose out of all particles
function poseFilter.get_pose()
  local wmax, imax = util.max(wp)
  return xp[imax], yp[imax], mod_angle(ap[imax])
end

---Caluclates weighted sample variance of current particles.
--@param x0 x coordinates of current particles
--@param y0 y coordinates of current particles
--@param a0 angles of current particles
--@return weighted sample variance of x coordinates, y coordinates, and angles
function poseFilter.get_sv(x0, y0, a0)
  local xs = 0.0
  local ys = 0.0
  local as = 0.0
  local ws = 0.0001

  for i = 1,N do
    local dx = x0 - xp[i]
    local dy = y0 - yp[i]
    local da = mod_angle(a0 - ap[i])
    xs = xs + wp[i]*dx^2
    ys = ys + wp[i]*dy^2
    as = as + wp[i]*da^2
    ws = ws + wp[i]
  end

  return math.sqrt(xs)/ws, math.sqrt(ys)/ws, math.sqrt(as)/ws
end


---Updates particles with respect to the detection of a landmark
--@param pos Table of possible positions for a landmark
--@param v x and y coordinates of detected landmark relative to robot
--@param rLandmarkFilter How much to adjust particles according to
--distance to landmark
--@param aLandmarkFilter How much to adjust particles according to 
--angle to landmark
local function landmark_observation(pos, v, rLandmarkFilter, aLandmarkFilter)
  local r = math.sqrt(v[1]^2 + v[2]^2)
  local a = math.atan2(v[2], v[1])
  local rSigma = .15*r + 0.10
  local aSigma = 5*math.pi/180
  local rFilter = rLandmarkFilter or 0.02
  local aFilter = aLandmarkFilter or 0.04

  --Calculate best matching landmark pos to each particle
  local dxp = {}
  local dyp = {}
  local dap = {}
  for ip = 1,N do
    local dx = {}
    local dy = {}
    local dr = {}
    local da = {}
    local err = {}
    for ipos = 1,#pos do
      dx[ipos] = pos[ipos][1] - xp[ip]
      dy[ipos] = pos[ipos][2] - yp[ip]
      dr[ipos] = math.sqrt(dx[ipos]^2 + dy[ipos]^2) - r
      da[ipos] = mod_angle(math.atan2(dy[ipos],dx[ipos]) - (ap[ip] + a))
      err[ipos] = (dr[ipos]/rSigma)^2 + (da[ipos]/aSigma)^2
    end
    local errMin, imin = util.min(err)

    --Update particle weights:
    wp[ip] = wp[ip] - errMin

    dxp[ip] = dx[imin]
    dyp[ip] = dy[imin]
    dap[ip] = da[imin]
  end
  --Filter toward best matching landmark position:
  for ip = 1,N do
--print(string.format("%d %.1f %.1f %.1f",ip,xp[ip],yp[ip],ap[ip]))
    xp[ip] = xp[ip] + rFilter * (dxp[ip] - r * math.cos(ap[ip] + a))
    yp[ip] = yp[ip] + rFilter * (dyp[ip] - r * math.sin(ap[ip] + a))
    ap[ip] = ap[ip] + aFilter * dap[ip]

    -- check boundary
    xp[ip] = math.min(xMax, math.max(-xMax, xp[ip]))
    yp[ip] = math.min(yMax, math.max(-yMax, yp[ip]))
  end
end

---Update particles according to a goal detection
--@param pos All possible positions of the goals
--For example, each post location is an entry in pos
--@param v x and y coordinates of detected goal relative to robot
--function poseFilter.goal_observation(pos, v)
---------------------------------------------------------------------------
-- Now we have two ambiguous goals to check
-- So we separate the triangulation part and the update part
---------------------------------------------------------------------------

function poseFilter.triangulate(pos,v)
  --Based on old code

  -- Use angle between posts (most accurate)
  -- as well as combination of post distances to triangulate
  local aPost = {}
  aPost[1] = math.atan2(v[1][2], v[1][1])
  aPost[2] = math.atan2(v[2][2], v[2][1])
  local daPost = mod_angle(aPost[1]-aPost[2])

  -- Radius of circumscribing circle
  local sa = math.sin(math.abs(daPost))
  local ca = math.cos(daPost)
  local rCircumscribe = goalWidth/(2*sa)

  -- Post distances
  local d2Post = {}
  d2Post[1] = v[1][1]^2 + v[1][2]^2
  d2Post[2] = v[2][1]^2 + v[2][2]^2
  local ignore, iMin = util.min(d2Post)

  -- Position relative to center of goal:
  local sumD2 = d2Post[1] + d2Post[2]
  local dGoal = math.sqrt(.5*sumD2)
  local dx = (sumD2 - goalWidth^2)/(4*rCircumscribe*ca)
  local dy = math.sqrt(math.max(.5*sumD2-.25*goalWidth^2-dx^2, 0))

  -- Predicted pose:
  local x = pos[iMin][1]
  x = x - util.sign(x) * dx
  local y = pos[iMin][2]
  y = util.sign(y) * dy
  local a = math.atan2(pos[iMin][2] - y, pos[iMin][1] - x) - aPost[iMin]

  pose={}
  pose.x=x
  pose.y=y
  pose.a=a
 
  aGoal = util.mod_angle((aPost[1]+aPost[2])/2)

  return pose,dGoal,aGoal
end

triangulate2 = function (pos,v)

  --New code (for OP)
   local aPost = {}
   local d2Post = {}

   aPost[1] = math.atan2(v[1][2], v[1][1])
   aPost[2] = math.atan2(v[2][2], v[2][1])
   d2Post[1] = v[1][1]^2 + v[1][2]^2
   d2Post[2] = v[2][1]^2 + v[2][2]^2
   d1 = math.sqrt(d2Post[1])
   d2 = math.sqrt(d2Post[2])

  --    vcm.add_debug_message(string.format(
  -- "===\n World: triangulation 2\nGoal dist: %.1f / %.1f\nGoal width: %.1f\n",
  -- d1, d2 ,goalWidth ))
  -- 
  -- 
  --    vcm.add_debug_message(string.format(
  -- "Measured goal width: %.1f\n",
  --  math.sqrt((v[1][1]-v[2][1])^2+(v[1][2]-v[2][2])^2)
  -- ))

   postfix=1
   --postfix=0

   if postfix>0 then

     if d1>d2 then 
       --left post correction based on right post
       -- v1=kcos(a1),ksin(a1)
       -- k^2 - 2k(v[2][1]cos(a1)+v[2][2]sin(a1)) + d2Post[2]-goalWidth^2 = 0
       local ca = math.cos(aPost[1])
       local sa = math.sin(aPost[1])
       local b = v[2][1]*ca+ v[2][2]*sa
       local c = d2Post[2]-goalWidth^2

       if b*b-c>0 then
         -- vcm.add_debug_message("Correcting left post\n")
         -- vcm.add_debug_message(string.format("Left post angle: %d\n",aPost[1]*180/math.pi))

         k1=b-math.sqrt(b*b-c)
         k2=b+math.sqrt(b*b-c)
         
    --          vcm.add_debug_message(string.format("d1: %.1f v1: %.1f %.1f\n",
    --         d1,v[1][1],v[1][2]))
    --          vcm.add_debug_message(string.format("k1: %.1f v1_1: %.1f %.1f\n",
    -- k1,k1*ca,k1*sa ))
    --          vcm.add_debug_message(string.format("k2: %.1f v1_2: %.1f %.1f\n",
    -- k2,k2*ca,k2*sa ))
    
         if math.abs(d2-k1)<math.abs(d2-k2) then
  	        v[1][1],v[1][2]=k1*ca,k1*sa
         else
	          v[1][1],v[1][2]=k2*ca,k2*sa
         end
       end
     else 
       --right post correction based on left post
       -- v2=kcos(a2),ksin(a2)
       -- k^2 - 2k(v[1][1]cos(a2)+v[1][2]sin(a2)) + d2Post[1]-goalWidth^2 = 0
       local ca=math.cos(aPost[2])
       local sa=math.sin(aPost[2])
       local b=v[1][1]*ca+ v[1][2]*sa
       local c=d2Post[1]-goalWidth^2
    
       if b*b-c>0 then
         k1=b-math.sqrt(b*b-c)
         k2=b+math.sqrt(b*b-c)
         
      --        vcm.add_debug_message(string.format("d2: %.1f v2: %.1f %.1f\n",
      --     d2,v[2][1],v[2][2]))
      --        vcm.add_debug_message(string.format("k1: %.1f v2_1: %.1f %.1f\n",
      -- k1,k1*ca,k1*sa ))
      --        vcm.add_debug_message(string.format("k2: %.1f v2_2: %.1f %.1f\n",
      -- k2,k2*ca,k2*sa ))
    
         if math.abs(d2-k1)<math.abs(d2-k2) then
            v[2][1],v[2][2]=k1*ca,k1*sa
         else
            v[2][1],v[2][2]=k2*ca,k2*sa
         end
       end
     end

   end

   --Use center of the post to fix angle
   vGoalX=0.5*(v[1][1]+v[2][1])
   vGoalY=0.5*(v[1][2]+v[2][2])
   rGoal = math.sqrt(vGoalX^2+vGoalY^2)

   if aPost[1]<aPost[2] then
     aGoal=-math.atan2 ( v[1][1]-v[2][1] , -(v[1][2]-v[2][2]) ) 
   else
     aGoal=-math.atan2 ( v[2][1]-v[1][1] , -(v[2][2]-v[1][2]) ) 
   end   

   ca=math.cos(aGoal)
   sa=math.sin(aGoal)
   
   local dx = ca*vGoalX-sa*vGoalY
   local dy = sa*vGoalX+ca*vGoalY

   local x0 = 0.5*(pos[1][1]+pos[2][1])
   local y0 = 0.5*(pos[1][2]+pos[2][2])

   local x = x0 - util.sign(x0)*dx
   local y = -util.sign(x0)*dy
   local a=aGoal
   if x0<0 then a=mod_angle(a+math.pi) end
   local dGoal = rGoal

   pose={}
   pose.x=x
   pose.y=y
   pose.a=a

 --  aGoal = util.mod_angle((aPost[1]+aPost[2])/2)

   return pose,dGoal,aGoal
end



local function goal_observation(pos1,pos2,v)

  --Get pose estimate from two goalpost locations
  if use_new_goalposts==1 then
    pose1,dGoal1=triangulate2(pos1,v)
    pose2,dGoal2=triangulate2(pos2,v)
  else
    pose1,dGoal1=triangulate(pos1,v)
    pose2,dGoal2=triangulate(pos2,v)
  end

  local x1,y1,a1=pose1.x,pose1.y,pose1.a
  local x2,y2,a2=pose2.x,pose2.y,pose2.a

  local rSigma1 = .25*dGoal1 + 0.20
  local rSigma2 = .25*dGoal2 + 0.20
  local aSigma = 5*math.pi/180
  local rFilter = rUnknownGoalFilter
  local aFilter = aUnknownGoalFilter

  for ip = 1,N do
    local xErr1 = x1 - xp[ip]
    local yErr1 = y1 - yp[ip]
    local rErr1 = math.sqrt(xErr1^2 + yErr1^2)
    local aErr1 = mod_angle(a1 - ap[ip])
    local err1 = (rErr1/rSigma1)^2 + (aErr1/aSigma)^2

    local xErr2 = x2 - xp[ip]
    local yErr2 = y2 - yp[ip]
    local rErr2 = math.sqrt(xErr2^2 + yErr2^2)
    local aErr2 = mod_angle(a2 - ap[ip])
    local err2 = (rErr2/rSigma2)^2 + (aErr2/aSigma)^2

    --Filter towards best matching goal:
    if err1>err2 then
      wp[ip] = wp[ip] - err2
      xp[ip] = xp[ip] + rFilter*xErr2
      yp[ip] = yp[ip] + rFilter*yErr2
      ap[ip] = ap[ip] + aFilter*aErr2
    else
      wp[ip] = wp[ip] - err1
      xp[ip] = xp[ip] + rFilter*xErr1
      yp[ip] = yp[ip] + rFilter*yErr1
      ap[ip] = ap[ip] + aFilter*aErr1
    end
  end
end



function poseFilter.post_both(v)
  goal_observation(goalUpper, goalLower, v)
end

function poseFilter.post_unknown(v)
  landmark_observation(postAll, v[1], rUnknownPostFilter, aUnknownPostFilter)
end

function poseFilter.post_left(v)
  landmark_observation(postLeft, v[1], rUnknownPostFilter, aUnknownPostFilter)
end

function poseFilter.post_right(v)
  landmark_observation(postRight, v[1], rUnknownPostFilter, aUnknownPostFilter)
end


---Updates weights of particles according to the detection of a line
--@param v z and y coordinates of center of line relative to robot
--@param a angle of line relative to angle of robot
function poseFilter.landmark_yellow(v)
  landmark_observation({landmarkYellow}, v, rLandmarkFilter, aLandmarkFilter)
end

function poseFilter.corner(v,a)
  landmark_observation(Lcorner,v,rCornerFilter,aCornerFilter)
--  line(v,a)--Fix heading
end


function poseFilter.line(v, a)
  -- line center
  x = v[1]
  y = v[2]
  r = math.sqrt(x^2 + y^2)

  w0 = .25 / (1 + r/2.0)

  -- TODO: wrap in loop for lua
  for ip = 1,N do
    -- pre-compute sin/cos of orientations
    ca = math.cos(ap[ip])
    sa = math.sin(ap[ip])

    -- compute line weight
    local wLine = w0 * (math.cos(4*(ap[ip] + a)) - 1)
    wp[ip] = wp[ip] + wLine

    local xGlobal = v[1]*ca - v[2]*sa + xp[ip]
    local yGlobal = v[1]*sa + v[2]*ca + yp[ip]

    wBounds = math.max(xGlobal - xBoundary, 0) + 
              math.max(-xGlobal - xBoundary, 0) + 
              math.max(yGlobal - yBoundary, 0) +
              math.max(-yGlobal - yBoundary, 0)
    wp[ip] = wp[ip] - (wBounds/.20)
  end
end

---Updates particles according to the movement of the robot.
--Moves each particle the distance that the robot has moved
--since the last update.
--@param dx distance moved in x direction since last update
--@param dy distance moved in y direction since last update
--@param da angle turned since last update
function poseFilter.odometry(dx, dy, da)
  for ip = 1,N do
    ca = math.cos(ap[ip])
    sa = math.sin(ap[ip])
    xp[ip] = xp[ip] + dx*ca - dy*sa
    yp[ip] = yp[ip] + dx*sa + dy*ca
    ap[ip] = ap[ip] + da
  end
end

---Set all particles to x,y,a=0,0,0.
--This function poseFilter.does not update the weights
function poseFilter.zero_pose()
  xp = vector.zeros(N)
  yp = vector.zeros(N)
  ap = vector.zeros(N)
end



---Adds noise to particle x,y coordinates and angle.
function poseFilter.addNoise()
  da = 2.0*math.pi/180.0
  dr = 0.01
  xp = xp + dr * vector.new(util.randn(N))
  yp = yp + dr * vector.new(util.randn(N))
  ap = ap + da * vector.new(util.randn(N))
end

---Resample particles.
--If enough particles have low enough weights, then
--replaces low-weighted particles with new random particles
--and new particles that are nearby high-weighted particles
function poseFilter.resample()
  -- resample particles

  local wLog = {}
  for i = 1,N do
    -- cutoff boundaries
    wBounds = math.max(xp[i]-xMax,0)+math.max(-xp[i]-xMax,0)+
              math.max(yp[i]-yMax,0)+math.max(-yp[i]-yMax,0)
    wLog[i] = wp[i] - wBounds/0.1
    xp[i] = math.max(math.min(xp[i], xMax), -xMax)
    yp[i] = math.max(math.min(yp[i], yMax), -yMax)
  end

  --Calculate effective number of particles
  wMax, iMax = util.max(wLog)
  -- total sum
  local wSum = 0
  -- sum of squares
  local wSum2 = 0
  local w = {}
  for i = 1,N do
    w[i] = math.exp(wLog[i] - wMax)
    wSum = wSum + w[i]
    wSum2 = wSum2 + w[i]^2
  end

  local nEffective = (wSum^2) / wSum2
  if nEffective > .25*N then
    return 
  end

  -- cum sum of weights
  -- wSum[i] = {cumsum(i), index}
  -- used for retrieving the sorted indices
  local wSum = {}
  wSum[1] = {w[1], 1}
  for i = 2,N do
     wSum[i] = {wSum[i-1][1] + w[i], i}
  end

  --normalize
  for i = 1,N do
    wSum[i][1] = wSum[i][1] / wSum[N][1]
  end

  --Add n more particles and resample high n weighted particles
  local rx = util.randu(N)
  local wSum_sz = #wSum
  for i = 1,N do 
    table.insert(wSum, {rx[i], N+i})
  end

  -- sort wSum min->max
  table.sort(wSum, function(a,b) return a[1] < b[1] end)

  -- resample (replace low weighted particles)
  xp2 = vector.zeros(N) 
  yp2 = vector.zeros(N)
  ap2 = vector.zeros(N)
  nsampleSum = 1
  ni = 1
  for i = 1,2*N do
    oi = wSum[i][2]
    if oi > N then
      xp2[ni] = xp[nsampleSum]
      yp2[ni] = yp[nsampleSum]
      ap2[ni] = ap[nsampleSum]
      ni = ni + 1
    else
      nsampleSum = nsampleSum + 1
    end
  end

  -- always put max particle
  xp2[1] = xp[iMax]
  yp2[1] = yp[iMax]
  ap2[1] = ap[iMax]

  xp = xp2
  yp = yp2
  ap = ap2
  wp = vector.zeros(N)
end

return poseFilter