----------------------------------------------------------------------
-- Oscillatory Walking
----------------------------------------------------------------------

require('util')
require('Body')
require('vector')
require('Config')
require('waveform')
require('Kinematics')
require('MotionState')

-- Setup 
----------------------------------------------------------------------

walk = MotionState.new(...)
local sensor = walk.sensor
local actuator = walk.actuator
walk:set_joint_access(0, 'all')
walk:set_joint_access(1, 'legs')

-- define velocity parameters
walk.velocity           = vector.new{0, 0, 0}
local velocity          = vector.new{0, 0, 0}
local v_limits          = vector.new(Config.walk.v_limits or {1, 1, 1})
local a_limits          = vector.new(Config.walk.a_limits or {1, 1, 1})

-- define default parameters
walk.parameters = {
  x_offset              = 0.025, -- meters
  y_offset              = 0.1,   -- meters
  z_offset              = -0.75, -- meters
  a_offset              = 0,     -- radians
  hip_pitch_offset      = 0,     -- radians
  x_shift_ratio         = 0.5,   -- ratio
  y_shift_ratio         = 0.5,   -- ratio
  y_swing_amplitude     = 0,     -- meters
  z_swing_amplitude     = 0,     -- meters
  r_swing_amplitude     = 0,     -- radians
  step_amplitude        = 0,     -- meters
  period_time           = 1,     -- seconds
  dsp_ratio             = 0.25,  -- ratio
  ankle_roll_fb         = 0,     -- ratio
  ankle_pitch_fb        = 0,     -- ratio
}

-- load config parameters
for k,v in pairs(walk.parameters) do
   walk.parameters[k] = Config.walk.parameters[k] or v
end

-- define local copies
local x_offset          = walk.parameters.x_offset
local y_offset          = walk.parameters.y_offset
local z_offset          = walk.parameters.z_offset
local a_offset          = walk.parameters.a_offset
local hip_pitch_offset  = walk.parameters.hip_pitch_offset
local x_shift_ratio     = walk.parameters.x_shift_ratio
local y_shift_ratio     = walk.parameters.y_shift_ratio
local y_swing_amplitude = walk.parameters.y_swing_amplitude
local z_swing_amplitude = walk.parameters.z_swing_amplitude
local r_swing_amplitude = walk.parameters.r_swing_amplitude
local step_amplitude    = walk.parameters.step_amplitude
local period_time       = walk.parameters.period_time
local dsp_ratio         = walk.parameters.dsp_ratio
local ankle_roll_fb     = walk.parameters.ankle_roll_fb
local ankle_pitch_fb    = walk.parameters.ankle_pitch_fb

-- initialize control variables
local active            = false
local stop_request      = false
local start_request     = false
local t0                = Body.get_time()
local t                 = t0
local q0                = scm:get_joint_position('legs')
local qstance           = vector.copy(q0)

-- Private
----------------------------------------------------------------------

local function limit(value, threshold)
  local threshold = math.abs(threshold)
  return math.min(math.max(value, -threshold), threshold)
end

local function update_parameters()
  -- update local gait parameters
  x_offset = walk.parameters.x_offset
  y_offset = walk.parameters.y_offset
  z_offset = walk.parameters.z_offset
  a_offset = walk.parameters.a_offset
  hip_pitch_offset = walk.parameters.hip_pitch_offset
  x_shift_ratio = walk.parameters.x_shift_ratio
  y_shift_ratio = walk.parameters.y_shift_ratio
  y_swing_amplitude = walk.parameters.y_swing_amplitude
  z_swing_amplitude = walk.parameters.z_swing_amplitude
  r_swing_amplitude = walk.parameters.r_swing_amplitude
  step_amplitude = walk.parameters.step_amplitude
  period_time = walk.parameters.period_time
  dsp_ratio = walk.parameters.dsp_ratio
  ankle_roll_fb = walk.parameters.ankle_roll_fb
  ankle_pitch_fb = walk.parameters.ankle_pitch_fb
end

local function update_velocity(dt)
  -- update local walking velocity
  local dv = walk.velocity - velocity
  dv_limits = dt*a_limits
  dv[1] = limit(dv[1], dv_limits[1])
  dv[2] = limit(dv[2], dv_limits[2])
  dv[3] = limit(dv[3], dv_limits[3])
  velocity = velocity + dv
  velocity[1] = limit(velocity[1], v_limits[1]) 
  velocity[2] = limit(velocity[2], v_limits[2]) 
  velocity[3] = limit(velocity[3], v_limits[3]) 
end

local function update_legs(qlegs)
  -- add gyro feedback to ankle and hip joints
  local gyro = sensor:get_ahrs('gyro')
  qlegs[5] = qlegs[5] + ankle_pitch_fb*gyro[2]
  qlegs[6] = qlegs[6] + ankle_roll_fb*gyro[1]
  qlegs[11] = qlegs[11] + ankle_pitch_fb*gyro[2]
  qlegs[12] = qlegs[12] + ankle_roll_fb*gyro[1]

  -- write joint angles to actuator shared memory 
  actuator:set_joint_position(qlegs, 'legs')
end

-- Public
----------------------------------------------------------------------

function walk:start()
  -- issue start request
  start_request = true
end

function walk:stop()
  -- issue stop request
  stop_request = true
end

function walk:is_active()
  -- return true if gait is active
  return active
end

function walk:set_velocity(vx, vy, va)
  walk.velocity[1] = vx
  walk.velocity[2] = vy
  walk.velocity[3] = va 
end

function walk:get_velocity()
  return vector.copy(velocity)
end

function walk:entry()
  self.running = true
  active = false
  update_parameters()
  t0 = Body.get_time()
  q0 = sensor:get_joint_position('legs')
end

function walk:update()
  if active then
   
    -- update timing and velocity
    local tlast = t
    t = Body.get_time()
    update_velocity(t - tlast)

    -- update phase
    local ph = 2*math.pi/period_time*(t - t0)
    local step_sin = waveform.step_sin(ph, dsp_ratio)
    local stride_cos = waveform.stride_cos(ph, dsp_ratio)

    -- calculate left foot trajectory
    local l_foot_pos = vector.zeros(6)
    l_foot_pos[1] = x_offset - velocity[1]*stride_cos
    l_foot_pos[2] = y_offset - velocity[2]*stride_cos
    l_foot_pos[6] = a_offset - velocity[3]*stride_cos
    if (ph < math.pi) then
      l_foot_pos[3] = z_offset + step_amplitude*step_sin
    else
      l_foot_pos[3] = z_offset
    end

    -- calculate right foot trajectory
    local r_foot_pos = vector.zeros(6) 
    r_foot_pos[1] = x_offset + velocity[1]*stride_cos
    r_foot_pos[2] =-y_offset + velocity[2]*stride_cos
    r_foot_pos[6] =-a_offset + velocity[3]*stride_cos
    if (ph > math.pi) then
      r_foot_pos[3] = z_offset - step_amplitude*step_sin
    else
      r_foot_pos[3] = z_offset
    end

    -- calculate torso trajectory
    local torso_pos = vector.zeros(6) 
    torso_pos[1] = velocity[1]*x_shift_ratio*math.sin(2*ph)
    torso_pos[2] = velocity[2]*y_shift_ratio*math.sin(2*ph)
                 - y_swing_amplitude*math.sin(ph)
    torso_pos[3] = z_swing_amplitude*-math.cos(2*ph)
    torso_pos[5] = hip_pitch_offset

    -- calculate inverse kinematics and add hip roll swing
    local q = Kinematics.inverse_legs(l_foot_pos, r_foot_pos, torso_pos)
    if (ph < math.pi) then 
      q[2] = q[2] + r_swing_amplitude*step_sin
    else
      q[8] = q[8] + r_swing_amplitude*step_sin
    end

    -- update legs with gyro stabilization
    update_legs(q)

    -- update gait parameters at the end of each cycle 
    if (ph > 2*math.pi) then
      update_parameters()
      t0 = t
    end

    -- check for start and stop requests
    if (math.abs(math.sin(ph)) < 0.025 and stop_request) then
       active = false
       stop_request = false
       t0 = t
       q0 = sensor:get_joint_position('legs')
       velocity = vector.new{0, 0, 0}
    elseif start_request then
       start_request = false
    end

  else
    -- calculate current walking stance
    local l_foot_pos = {x_offset, y_offset, z_offset, 0, 0, a_offset}
    local r_foot_pos = {x_offset,-y_offset, z_offset, 0, 0, -a_offset}
    local torso_pos = {0, 0, 0, 0, hip_pitch_offset, 0}
    local qstance = Kinematics.inverse_legs(l_foot_pos, r_foot_pos, torso_pos)

    -- update stance
    t = Body.get_time()
    update_parameters()
    local d = util.min{(t - t0)/2, 1}
    local q = q0 + d*(vector.new(qstance) - vector.new(q0))
    update_legs(q)

    -- check for start and stop requests
    if (t - t0 > 2) and start_request then
      active = true
      start_request = false
      t0 = t 
    elseif stop_request then
      stop_request = false
    end
  end
end

function walk:exit()
  self.running = false
end

return walk
