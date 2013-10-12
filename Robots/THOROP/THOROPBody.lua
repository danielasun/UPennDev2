--------------------------------
-- Body abstraction for THOR-OP
-- (c) 2013 Stephen McGill, Seung-Joon Yi
--------------------------------
local mp         = require'msgpack'
local udp        = require'udp'


-- Webots THOR-OP Body sensors
local use_camera = true
local use_lidar_head  = false
local use_lidar_chest  = false
local use_pose   = true
local use_joint_feedback = false


-- Shared memory for the joints
require'jcm'
-- Shared memory for vision of the world
require'vcm'
-- Shared memory for world 
require'wcm'

-- Utilities
local unix         = require'unix'
local vector       = require'vector'
local quaternion   = require'quaternion'
local Transform    = require'Transform'
local util         = require'util'
-- For the real body
local libDynamixel   = require'libDynamixel'
local DP2 = libDynamixel.DP2
local libMicrostrain = require'libMicrostrain'

local DEG_TO_RAD = math.pi/180
local RAD_TO_DEG = 180/math.pi

local Body = {}
Body.DEG_TO_RAD = DEG_TO_RAD
Body.RAD_TO_DEG = RAD_TO_DEG
local get_time = unix.time

--------------------------------
-- Shared memory layout
local indexHead = 1   -- Head: 1 2
local nJointHead = 2
local indexLArm = 3   --LArm: 3 4 5 6 7 8 9
local nJointLArm = 7    
local indexLLeg = 10  --LLeg: 10 11 12 13 14 15
local nJointLLeg = 6
local indexRLeg = 16  --RLeg: 16 17 18 19 20 21
local nJointRLeg = 6
local indexRArm = 22  --RArm: 22 23 24 25 26 27 28
local nJointRArm = 7
local indexWaist = 29  --Waist: 29 30
local nJointWaist = 2
-- 6 Fingers for gripping
-- 1 servo for lidar panning
local indexLGrip = 31
local nJointLGrip = 3
local indexRGrip = 34
local nJointRGrip = 3
-- One motor for lidar panning
local indexLidar = 37
local nJointLidar = 1
local nJoint = 37

local jointNames = {
	"Neck","Head", -- Head
	-- Left Arm
	"ShoulderL", "ArmUpperL", "LeftShoulderYaw",
	"ArmLowerL","LeftWristYaw","LeftWristRoll","LeftWristYaw2",
	-- Left leg
	"PelvYL","PelvL","LegUpperL","LegLowerL","AnkleL","FootL",
	-- Right leg
	"PelvYR","PelvR","LegUpperR","LegLowerR","AnkleR","FootR",
	--Right arm
	"ShoulderR", "ArmUpperR", "RightShoulderYaw","ArmLowerR",
	"RightWristYaw","RightWristRoll","RightWristYaw2",
	-- Waist
	"TorsoPitch","TorsoYaw",
	-- Gripper
	"l_wrist_grip1","l_wrist_grip2","l_wrist_grip3",
	"r_wrist_grip1","r_wrist_grip2","r_wrist_grip3",
	-- lidar movement
	"ChestLidarPan",
}

local passiveJointNames = {
  "l_wrist_grip1_2","l_wrist_grip2_2","l_wrist_grip3_2",
  "r_wrist_grip1_2","r_wrist_grip2_2","r_wrist_grip3_2",
}

assert(nJoint==#jointNames,'bad jointNames!')

local parts = {
	['Head']=vector.count(indexHead,nJointHead),
	['LArm']=vector.count(indexLArm,nJointLArm),
	['LLeg']=vector.count(indexLLeg,nJointLLeg),
	['RLeg']=vector.count(indexRLeg,nJointRLeg),
	['RArm']=vector.count(indexRArm,nJointRArm),
	['Waist']=vector.count(indexWaist,nJointWaist),
	['LGrip']=vector.count(indexLGrip,nJointLGrip),
  ['RGrip']=vector.count(indexRGrip,nJointRGrip),
  ['Lidar']=vector.count(indexLidar,nJointLidar)
}
local inv_parts = {}
for name,list in pairs(parts) do
	for _,idx in ipairs(list) do inv_parts[idx]=name end
end

--------------------------------
-- Servo parameters
local servo = {}
servo.joint_to_motor={
  30,29,  --Head yaw/pitch
  2,4,6,8,10,12,14, --LArm
  16,18,20,22,24,26, -- left leg
  15,17,19,21,23,25, -- right leg
  1,3,5,7,9,11,13,  --RArm
  27,28, --Waist yaw/pitch
  32,34,36, -- left gripper (thumb, index, big&not_thumb)
  31,33,35, -- right gripper (thumb, index, big&not_thumb)
  37, -- Lidar pan
}
assert(#servo.joint_to_motor==nJoint,'Bad servo id map!')

local motor_parts = {}
for name,list in pairs(parts) do
	motor_parts[name] = vector.zeros(#list)
	for i,idx in ipairs(list) do
		motor_parts[name][i] = servo.joint_to_motor[idx]
	end
end

-- Make the reverse map
local motor_to_joint = {}
for j,m in ipairs(servo.joint_to_motor) do
	motor_to_joint[m] = j
end
servo.motor_to_joint = motor_to_joint

--http://support.robotis.com/en/product/dynamixel_pro/control_table.htm#Actuator_Address_611
-- TODO: Use some loop based upon MX/NX
-- TODO: some pros are different
servo.steps = 2 * vector.new({
  151875,151875, -- Head
  251000,251000,251000,251000,151875,151875,151875, --LArm
  251000,251000,251000,251000,251000,251000, --LLeg
  251000,251000,251000,251000,251000,251000, --RLeg
  251000,251000,251000,251000,151875,151875,151875, --RArm
  251000,251000, -- Waist
  2048,2048,2048, -- Left gripper
  2048,2048,2048, -- Right gripper
  2048, -- Lidar pan
})
assert(#servo.steps==nJoint,'Bad servo steps!')

-- NOTE: Servo direction is webots/real robot specific
servo.direction = vector.new({
  1,1, -- Head
  1,-1,1,1,1,1,1, --LArm 
  ------
  -1, -1,1,   1,  -1,1, --LLeg
  -1, -1,-1, -1,  1,1, --RLeg
  ------
  -1,-1,1,-1, 1,1,1, --RArm
  1,1, -- Waist
  1,1,-1, -- left gripper
  1,1,-1, -- right gripper
  -1, -- Lidar pan
})
assert(#servo.direction==nJoint,'Bad servo direction!')

-- TODO: Offset in addition to bias?
servo.rad_bias = vector.new({
  0,0, -- Head
  -90,90,-90,45,90,0,0, --LArm
  0,0,0,-45,0,0, --LLeg
  0,0,0,45,0,0, --RLeg
  90,-90,90,-45,-90,0,0, --RArm
  0,0, -- Waist
  0,0,0, -- left gripper
  0,0,0, -- right gripper
  0, -- Lidar pan
})*DEG_TO_RAD
assert(#servo.rad_bias==nJoint,'Bad servo rad_bias!')

--SJ: Arm servos should at least move up to 90 deg
servo.min_rad = vector.new({
  -90,-80, -- Head
  -90, 0, -90, -140,      -180,-87,-180, --LArm  
  -175,-175,-175,-175,-175,-175, --LLeg
  -175,-175,-175,-175,-175,-175, --RLeg
  -90,-87,-90,-140,       -180,-87,-180, --RArm
  -90,-45, -- Waist
  -32,-12,-12, -- left gripper
  -12,-32,-32, -- right gripper
  -60, -- Lidar pan
})*DEG_TO_RAD
assert(#servo.min_rad==nJoint,'Bad servo min_rad!')

servo.max_rad = vector.new({
  90,80, -- Head
  160,87,90,-25,     180,87,180, --LArm  
  175,175,175,175,175,175, --LLeg
  175,175,175,175,175,175, --RLeg
  160,-0,90,-25,     180,87,180, --RArm  
  90,45, -- Waist
  12,32,32, -- left gripper
  32,12,12, -- right gripper
  60, -- Lidar pan
})*DEG_TO_RAD
assert(#servo.max_rad==nJoint,'Bad servo max_rad!')

-- Convienence tables to go between steps and radians
servo.moveRange = 360 * DEG_TO_RAD * vector.ones(nJoint)
-- Step<-->Radian ratios
servo.to_radians = vector.zeros(nJoint)
servo.to_steps = vector.zeros(nJoint)
for i,nsteps in ipairs(servo.steps) do
  servo.to_steps[i] = nsteps / servo.moveRange[i]
  servo.to_radians[i] = servo.moveRange[i] / nsteps
end
-- Set the step zero
-- NOTE: rad zero is always zero
servo.step_zero = vector.new(servo.steps) / 2
for i,nsteps in ipairs(servo.steps) do
  -- MX is halfway, while NX is 0 and goes positive/negative
  if nsteps~=4096 then servo.step_zero[i] = 0 end
end

-- TODO: How is direction used?
-- Add the bias in to the min/max helper tables
servo.step_bias = vector.zeros(nJoint)
servo.min_step  = vector.zeros(nJoint)
servo.max_step  = vector.zeros(nJoint)
for i, bias in ipairs(servo.rad_bias) do
  servo.step_bias[i] = bias * servo.to_steps[i]
end

-- Clamp the radian within the min and max
-- Used when sending packets and working with actuator commands
local radian_clamp = function( idx, radian )
  --print('clamp...',idx,radian,servo.min_rad[idx],servo.max_rad[idx])
  return math.min(math.max(radian, servo.min_rad[idx]), servo.max_rad[idx])
end

-- Radian to step, using offsets and biases
local make_joint_step = function( idx, radian )
  radian = radian_clamp( idx, radian )
	local step = math.floor(servo.direction[idx] * radian * servo.to_steps[idx]
	+ servo.step_zero[idx] + servo.step_bias[idx])
	return step
end

-- Step to radian
local make_joint_radian = function( idx, step )
	local radian = servo.direction[idx] * servo.to_radians[idx] * 
	(step - servo.step_zero[idx] - servo.step_bias[idx])
	return radian
end

--------------------------------
-- Legacy API
Body.set_syncread_enable = function()
end

----------------------
-- Body sensor positions
-- jcm should be the API compliance test
for sensor, pointer in pairs(jcm.sensorPtr) do
  local tread_ptr = jcm.treadPtr[sensor]
  local treq_ptr  = jcm.trequestPtr[sensor]
  local get_key  = 'get_sensor_'..sensor
  if tread_ptr then
  	local get_func = function(idx,idx2)
  		if idx then
        -- Return the values from idx to idx2
        if idx2 then
          local up2date = true
          for i=idx,idx2 do
            if treq_ptr[i]>tread_ptr[i] then up2date=false break end
          end
          return vector.new(pointer:table(idx,idx2)), up2date
        end 
        return pointer[idx], tread_ptr[idx]>treq_ptr[idx]
      end
      -- If no idx is supplied, then return the values of all joints
      local up2date = true
      for i=1,nJoint do
        if treq_ptr[i]>tread_ptr[i] then up2date=false break end
      end
  		return vector.new(pointer:table()), up2date
  	end
    Body[get_key] = get_func
    -- Do not set these as anthropomorphic
    -- overwrite if foot
    if sensor:find'foot' then
      Body[get_key] = function()
        return vector.new(pointer:table()), treq_ptr[1]<tread_ptr[1]
      end
    end
    --------------------------------
    -- Anthropomorphic access to jcm
    -- TODO: Do not use string concatenation to call the get/set methods of Body
    for part,jlist in pairs( parts ) do
      local a = jlist[1]
      local b = jlist[#jlist]
      Body['get_'..part:lower()..'_'..sensor] = function(idx)
        if idx then return get_func(jlist[idx]) end
        return get_func(a,b)
      end -- Get
    end -- anthropomorphic
    --------------------------------
  else
    -- Override for non-dynamixel (non-anthropomorphic) sensors
    local get_func = function(idx,idx2)
      if idx then
        -- Return the values from idx to idx2
        if idx2 then return vector.new(pointer:table(idx,idx2)) end 
        return pointer[idx]
      end
      -- If no idx is supplied, then return the values of all joints
      return vector.new(pointer:table())
    end
    Body[get_key] = get_func
  end -- if treadptr
end

----------------------
-- Body sensor read requests
-- jcm should be the API compliance test
for sensor, pointer in pairs(jcm.readPtr) do
  local treq_ptr = jcm.trequestPtr[sensor]
  local req_key = 'request_'..sensor
  local req_func = function(idx)
    local t = get_time()
    local qt = type(idx)
    if qt=='number' then
      pointer[idx] = 1
      treq_ptr[idx] = t
    elseif qt=='table' then
      for _,i in ipairs(idx) do
        pointer[i] = 1
        treq_ptr[i] = t
      end
    else
      -- All joint request
      for i=1,nJoint do
        pointer[i] = 1
        treq_ptr[i] = t
      end
    end
    return
	end
  Body[req_key] = req_func
  -- overwrite if foot
  if sensor:find'foot' then
    Body[req_key] = function()
      pointer[1] = 1
      treq_ptr[1] = get_time()
    end
  end
  ---------------------
  if not sensor:find'foot' then
    -- Anthropomorphic --
    for part,jlist in pairs( parts ) do
    	local a = jlist[1]
    	local b = jlist[#jlist]
      local read_key = 'read_'..sensor
    	Body['request_'..part:lower()..'_'..sensor] = function(idx)
    		if idx then return req_func(jlist[idx]) end
    		return req_func(jlist)
    	end -- Set
    end -- anthropomorphic
  ----------------------
  end
  ----------------------
end

----------------------
-- Body actuator commands
-- jcm should be the API compliance test
for actuator, pointer in pairs(jcm.actuatorPtr) do
  local get_key = 'get_actuator_'..actuator
  local set_key = 'set_actuator_'..actuator
  local write_ptr = jcm.writePtr[actuator]
  
	 local set_func = function(val,idx)
   --print('setting a write')
    if type(val)=='number' then
      if type(idx)=='number' then
        pointer[idx]   = val
        write_ptr[idx] = 1
        return
      else
        for _,i in ipairs(idx) do
          pointer[i]   = val
          write_ptr[i] = 1
        end
        return
      end
    end
    if not idx then
      for i,v in ipairs(val) do
        pointer[i]   = v
        write_ptr[i] = 1
      end
      return
    end
    if type(idx)=='number' then
      for i,v in ipairs(val) do
        local offset = idx+i-1
        pointer[offset]   = v
        write_ptr[offset] = 1
      end
      return
    else
      -- ji: joint index. vi: value index
      for vi,ji in ipairs(idx) do
        pointer[ji]   = val[vi]
        write_ptr[ji] = 1
      end
      return
    end
	end
  Body[set_key] = set_func
	local get_func = function(idx,idx2)
		if idx then
      -- Return the values from idx to idx2
      if idx2 then return vector.new(pointer:table(idx,idx2)) end 
      return pointer[idx]
    end
    -- If no idx is supplied, then return the values of all joints
    -- TODO: return as a table or carray?
		return vector.new(pointer:table())
	end
  Body[get_key] = get_func
  --------------------------------
  -- Anthropomorphic access to jcm
  -- TODO: Do not use string concatenation to call the get/set methods of Body
  for part,jlist in pairs( parts ) do
  	local a = jlist[1]
  	local b = jlist[#jlist]
  	Body['get_'..part:lower()..'_'..actuator] = function(idx)
  		if idx then return get_func(jlist[idx]) end
  		return get_func(a,b)
  	end -- Get
  	Body['set_'..part:lower()..'_'..actuator] = function(val,i)
  		if type(i)=='number' then
        local idx = jlist[i]
        if actuator=='command_position' then val = radian_clamp(idx,val) end
        set_func(val,idx)
        return val
      end
      -- With no idx, val is number or table
      -- Make sure to clamp this value
      -- If val is a number to set all limb joints
      if type(val)=='number' then
        local values
        -- clamp just for command position!
        if actuator=='command_position' then
          values = {}
          for i,idx in ipairs(jlist) do values[i]=radian_clamp(idx,val) end
        else
          values = val*vector.ones(#jlist)
        end
        set_func(values,a)
        return values
      end
      -- If val is a set of values for each limb joints
      if actuator=='command_position' then
        for i,idx in ipairs(jlist) do val[i]=radian_clamp(idx,val[i]) end
      end
  		set_func(val,a)
      return val
  	end -- Set
  end -- anthropomorphic
  --------------------------------
end


--SJ: I reverted them back

-- TODO: should be in body or a Grip module?
-- Grip module may have more advanced techniques...
-- More gripper functions
-- TODO: Use body actuator access to JCM
Body.set_lgrip_percent = function( percent )
  percent = math.min(math.max(percent,0),1)
  -- Convex combo
  for idx=indexLGrip,indexLGrip+nJointLGrip-1 do
    local radian = (1-percent)*servo.min_rad[idx] + percent*servo.max_rad[idx]
    jcm.actuatorPtr.command_position[idx] = radian
  end
end
Body.set_rgrip_percent = function( percent )
  percent = math.min(math.max(percent,0),1)
  -- Convex combo
  for idx=indexRGrip,indexRGrip+nJointRGrip-1 do
    local radian = (1-percent) * servo.min_rad[idx] + percent*servo.max_rad[idx]
    jcm.actuatorPtr.command_position[idx] = radian
  end
end


--------------------------------
-- TODO: Hardness
Body['set_actuator_hardness'] = function(val,idx)
-- TODO
end
Body['get_actuator_hardness'] = function(idx,idx2)
  -- TODO
end
for part,jlist in pairs( parts ) do
	Body['get_'..part:lower()..'_hardness'] = function(idx)
    -- TODO
	end -- Get
	Body['set_'..part:lower()..'_hardness'] = function(val,idx)
		-- TODO
	end -- Set
end -- anthropomorphic
--------------------------------




----------------------
-- Inverse Kinematics
local Kinematics = require'THOROPKinematics'

-- Check the error from a desired transform tr
-- to a forwards kinematics of in IK solution q
local function check_ik_error( tr, tr_check, pos_tol, ang_tol )
  -- Tolerate a 1mm error in distance  
  pos_tol = pos_tol or 0.001
  ang_tol = ang_tol or 0.1*DEG_TO_RAD

	local position_error = math.sqrt(
	( tr_check[1]-tr[1] )^2 +
	( tr_check[2]-tr[2] )^2 +
	( tr_check[3]-tr[3] )^2 )

	local angle_error = math.sqrt(
	util.mod_angle( tr_check[4]-tr[4] )^2 +
	util.mod_angle( tr_check[5]-tr[5] )^2 +
	util.mod_angle( tr_check[6]-tr[6] )^2 )

	-- If within tolerance, return true
  local in_tolerance = true
	if position_error>pos_tol then in_tolerance=false end
  if angle_error>ang_tol then in_tolerance=false end

  if not in_tolerance then
    print(string.format("tr0:%.2f %.2f %.2f %.2f %.2f %.2f tr:%.2f %.2f %.2f %.2f %.2f %.2f",
    tr_check[1],
    tr_check[2],
    tr_check[3],
    tr_check[4]*RAD_TO_DEG,
    tr_check[5]*RAD_TO_DEG,
    tr_check[6]*RAD_TO_DEG,
    tr[1],
    tr[2],
    tr[3],
    tr[4]*RAD_TO_DEG,
    tr[5]*RAD_TO_DEG,
    tr[6]*RAD_TO_DEG
    ))
    print(string.format("LArm: %.1f %.1f %.1f %.1f %.1f %.1f %.1f",unpack(
      vector.new(Body.get_larm_command_position())*RAD_TO_DEG     ) ))
    print(string.format("RArm: %.1f %.1f %.1f %.1f %.1f %.1f %.1f",unpack(
      vector.new(Body.get_rarm_command_position())*RAD_TO_DEG     ) ))
--    print(string.format("perr:%.4f aerr:%.2f",position_error, angle_error*Body.RAD_TO_DEG))
  end
	return in_tolerance
end

--6DOF IK
Body.get_inverse_larm_6dof = function( qL, trL, pos_tol, ang_tol )
  local qL_target = Kinematics.inverse_l_arm(trL, qL)
  qL_target[7] = 0; --Fix for 7DOF functions
  if not check_ik_error( trL, trL_check, pos_tol, ang_tol ) then
    print("unknown IK error")
    return
  end
  --Check range
  for i=1,nJointLArm do
    if qL_target[i]<servo.min_rad[indexLArm+i-1] or
      qL_target[i]>servo.max_rad[indexLArm+i-1] then
      print("out of range",i,"at ",qL_target[i])
      return
    end
  end
  return qL_target
end

Body.get_inverse_rarm_6dof = function( qR, trR, pos_tol, ang_tol )
  local qR_target = Kinematics.inverse_r_arm(trR, qR)
  qR_target[7] = 0; --Fix for 7DOF functions
  local trR_check = Kinematics.r_arm_torso_7(qR_target)
  if not check_ik_error( trR, trR_check, pos_tol, ang_tol ) then
    print("unknown IK error")
    return
  end
  --Check range
  for i=1,nJointRArm do
    if qR_target[i]<servo.min_rad[indexRArm+i-1] or
      qR_target[i]>servo.max_rad[indexRArm+i-1] then
      print("out of range",i)
      return
    end
  end
  return qR_target
end


-- Can we go from angle q to position p?
Body.get_inverse_larm = function( qL, trL, lShoulderYaw, pos_tol, ang_tol )
--7DOF IK
  if not lShoulderYaw then lShoulderYaw = qL[3]  end
  local qL_target = Kinematics.inverse_l_arm_7(trL,qL,lShoulderYaw)
  local trL_check = Kinematics.l_arm_torso_7(qL_target)
--Check range
  for i=1,nJointLArm do
    if qL_target[i]<servo.min_rad[indexLArm+i-1] or
      qL_target[i]>servo.max_rad[indexLArm+i-1] then
      print("out of range",i,"at ",qL_target[i]*RAD_TO_DEG)
      return
    end
  end

	if not check_ik_error( trL, trL_check, pos_tol, ang_tol ) then
    print("unknown IK error")
    return
  end
  
  return qL_target
end

Body.get_inverse_rarm = function( qR, trR, rShoulderYaw , pos_tol, ang_tol )  
  if not rShoulderYaw then rShoulderYaw = qR[3] end
  local qR_target = Kinematics.inverse_r_arm_7(trR, qR,rShoulderYaw)
  local trR_check = Kinematics.r_arm_torso_7(qR_target)
  --Check range
  for i=1,nJointRArm do
    if qR_target[i]<servo.min_rad[indexRArm+i-1] or
      qR_target[i]>servo.max_rad[indexRArm+i-1] then
      print("out of range",i,"at ",qR_target[i]*RAD_TO_DEG)
      return
    end
  end

  if not check_ik_error( trR, trR_check, pos_tol, ang_tol ) then
    print("unknown IK error")
    return
  end

  return qR_target
--
--  return Body.get_inverse_rarm_6dof(qR,trR,pos_tol,ang_tol)
end





-- Take in joint angles and output an {x,y,z,r,p,yaw} table

-- SJ: Now separated into two functions to get rid of directly calling IK
Body.get_forward_larm = function(qL)
--  local pLArm = Kinematics.l_arm_torso( qL )
  assert(#qL==7, "Arm FK requires 7 joints")
  local pLArm = Kinematics.l_arm_torso_7( qL )
  return pLArm
end
Body.get_forward_rarm = function(qR)  
--  local pRArm = Kinematics.r_arm_torso( qR )
  assert(#qR==7, "Arm FK requires 7 joints")
  local pRArm = Kinematics.r_arm_torso_7( qR )
  return pRArm
end

--Return the WRIST position (to test self collision)
Body.get_forward_lwrist = function(qL)
--  local pLArm = Kinematics.l_arm_torso( qL )
  assert(#qL==7, "Arm FK requires 7 joints")
  local pLArm = Kinematics.l_wrist_torso( qL )
  return pLArm
end
Body.get_forward_rwrist = function(qR)  
--  local pRArm = Kinematics.r_arm_torso( qR )
  assert(#qR==7, "Arm FK requires 7 joints")
  local pRArm = Kinematics.r_wrist_torso( qR )
  return pRArm
end


Body.get_inverse_rwrist = function( qR, trR, rShoulderYaw , pos_tol, ang_tol )
  if not rShoulderYaw then rShoulderYaw = qR[3] end
  local qR_target = Kinematics.inverse_r_wrist(trR, qR,rShoulderYaw)
  return qR_target
end

Body.get_inverse_lwrist = function( qL, trL, lShoulderYaw , pos_tol, ang_tol )
  if not lShoulderYaw then lShoulderYaw = qL[3] end
  local qL_target = Kinematics.inverse_l_wrist(trL, qL,lShoulderYaw)
  return qL_target
end

Body.get_inverse_arm_given_wrist = function( q, tr)
  local q_target = Kinematics.inverse_arm_given_wrist(tr,q)
  return q_target
end

-- SJ: sensed position can be noisy
-- So we should use current command position instead
Body.get_forward_larm_command = function()
--	local qLArm = Body.get_larm_position()
  local qLArm = Body.get_larm_command_position()
	local pLArm = Kinematics.l_arm_torso_7( qLArm )
  return pLArm
end
Body.get_forward_rarm_command = function()
--	local qRArm = Body.get_rarm_position()
  local qRArm = Body.get_rarm_command_position()
	local pRArm = Kinematics.r_arm_torso_7( qRArm )
  return pRArm
end



--SJ: those functions are not used at all in whole codebase
--[[
-- Change the joints via IK
Body.set_inverse_larm = function( dTrans )
  -- Perform FK to get current coordinates
  local p = Body.get_forward_larm()
  -- Increment the position
  p = p + dTrans 
  -- Set the shm to reflect the inverse kinematics solution
  local target = Body.get_inverse_larm(p)
  -- Check if the new position is invalid  
  if not target then return false end
  -- Update the Body command
  Body.set_larm_command_position(target)
  -- Return true upon success
  return true
end

Body.set_inverse_rarm = function( dTrans )
  -- Perform FK to get current coordinates
  local p = Body.get_forward_rarm()
  -- Increment the position
  p = p + dTrans 
  -- Set the shm to reflect the inverse kinematics solution
  local target = Body.get_inverse_rarm(p)
  -- Check if the new position is invalid  
  if not target then return false end
  -- Update the Body command
  Body.set_rarm_command_position(target)
  -- Return true upon success
  return true
end
--]]


-- TODO: Write functions to modify transform in directions

----------------------
-- Sensor access functions for convienence
-- TODO: Lidar scans should return metadata, too
Body.get_chest_lidar = function()
  return carray.float( vcm.get_chest_lidar_scan(), 1081 )
end
Body.get_head_lidar = function()
  return carray.float( vcm.get_head_lidar_scan(), 1081 )
end
Body.set_chest_lidar = function( data )
	vcm.set_chest_lidar_scan( data )
	vcm.set_chest_lidar_t( Body.get_time() )
end
Body.set_head_lidar = function( data )
	vcm.set_head_lidar_scan( data )
	vcm.set_head_lidar_t( Body.get_time() )
end

----------------------
-- More standard api functions
local dynamixels = {}
local dynamixel_fds = {}
local fd_dynamixels = {}
local motor_dynamixels = {}
local microstrain
Body.entry = function()
  if OPERATING_SYSTEM~='darwin' then
    dynamixels.right_arm = libDynamixel.new_bus'/dev/ttyUSB0'
    dynamixels['left_arm'] = libDynamixel.new_bus'/dev/ttyUSB1'
    dynamixels['right_leg'] = libDynamixel.new_bus'/dev/ttyUSB2'
    dynamixels['left_leg'] = libDynamixel.new_bus'/dev/ttyUSB3'
    microstrain = libMicrostrain.new_microstrain'/dev/ttyACM0'
  else
    dynamixels.right_arm = libDynamixel.new_bus'/dev/cu.usbserial-FTT3ABW9A'
    dynamixels['left_arm'] = libDynamixel.new_bus'/dev/cu.usbserial-FTT3ABW9B'
    dynamixels['right_leg'] = libDynamixel.new_bus'/dev/cu.usbserial-FTT3ABW9C'
    dynamixels['left_leg'] = libDynamixel.new_bus'/dev/cu.usbserial-FTT3ABW9D'
    microstrain = libMicrostrain.new_microstrain'/dev/cu.usbmodem1421'
  end
  -- motor ids
  dynamixels.right_arm.nx_ids =
    {1,3,5,7,9,11,13}
  dynamixels.left_arm.nx_ids =
    {2,4,6,8,10,12,14, --[[head]] 29,30 }
  dynamixels.right_leg.nx_ids = 
    {15,17,19,21,23,25, --[[waist pitch]]28}
  dynamixels.left_leg.nx_ids =
    {16,18,20,22,24,26, --[[waist]]27}
  --
  --dynamixels.right_arm.mx_ids = { --[[31,33,35]] },
  dynamixels.left_arm.mx_ids =
    { --[[32,34,36,]] --[[lidar]] 37}
  --

  --
  for _,d in pairs(dynamixels) do
    table.insert(dynamixel_fds,d.fd)
    fd_dynamixels[d.fd] = d
    for _,id in ipairs(d.nx_ids) do
      motor_dynamixels[id]=d
    end
  end

  --
  microstrain:ahrs_on()
  table.insert(dynamixel_fds,microstrain.fd)
  microstrain.t_diff = 0
  microstrain.t_read = 0
  --
end

local process_register_read = {
  position = function(idx,val,t)
    jcm.sensorPtr.position[idx] = Body.make_joint_radian( idx, val )
    jcm.treadPtr.position[idx]  = t
  end,
  rfoot = function(idx,val,t)
    local offset = idx-20
    --print('got rfoot!',offset,idx)
    local data = carray.short( string.char(unpack(val)) )
    for i=1,#data do
      jcm.sensorPtr.rfoot[offset+i] = 3.3*data[i]/4096-1.65
    end
    jcm.treadPtr.rfoot[1] = t
  end,
  lfoot = function(idx,val,t)
    local offset = idx-14
    --print('got lfoot!',offset,idx)
    local data = carray.short( string.char(unpack(val)) )
    for i=1,#data do
      jcm.sensorPtr.lfoot[offset+i] = 3.3*data[i]/4096-1.65
    end
    jcm.treadPtr.lfoot[1]  = t
  end,
  load = function(idx,v,t)
    if v>=1024 then v = v - 1024 end
    local load_ratio = v/10.24
    jcm.sensorPtr.load[idx] = load_ratio
    jcm.treadPtr.load[idx]  = t
  end
}

local function process_fd(ready_fd)
  local d   = fd_dynamixels[ready_fd]
  local buf = unix.read(ready_fd)
  assert(buf,'no read in process fd')
  --
  if not d then -- assume microstrain
    local gyro = carray.float(buf:sub( 7,18):reverse())
    local rpy  = carray.float(buf:sub(21,32):reverse())
    -- set to memory
    jcm.set_sensor_rpy{  rpy[2], rpy[3], -rpy[1]}
    jcm.set_sensor_gyro{gyro[2],gyro[3],-gyro[1]}
    -- done reading
    local t_read = unix.time()
    microstrain.t_diff = t_read - microstrain.t_read
    microstrain.t_read = t_read
    --print('microstrain rate',1/microstrain.t_diff)
    return false
  end
  --print('reading from',d.ttyname)
  if d.n_expect_read<=0 or not d.read_register then return false end
  -- assume dynamixel
  local status_packets
  d.str = d.str..buf
  status_packets, d.str = DP2.input( d.str )
  d.n_expect_read = d.n_expect_read - #status_packets
  --print('Got',#d.str,#status_packets,d.n_expect_read,d.ttyname)
  local values = {}
  for _,s in ipairs(status_packets) do
    local status = DP2.parse_status_packet( s )
    local read_parser = libDynamixel.byte_to_number[ #status.parameter ]
    local idx = motor_to_joint[status.id]
    local val
    if read_parser then
      val = read_parser( unpack(status.parameter) )
    else
      val = status.parameter
    end
    -- set into shm
    local f = process_register_read[d.read_register]
    if f then
      f(idx,val,unix.time())
    else
      --print('d.read_register',d.read_register)
      jcm.sensorPtr[d.read_register][idx] = val
      jcm.treadPtr[d.read_register][idx]  = unix.time()
    end
    --
  end
  -- return if still reading
  return d.n_expect_read>0
end

Body.update = function()

  for _,d in pairs(dynamixels) do
    --util.ptable(d)
    d.cmd_pkts = {}
    d.read_pkts = {}
    d.n_expect_read = 0
    d.read_register = nil
  end

  -- Loop through the registers
  for register,is_writes in pairs(jcm.writePtr) do
    --
    local set_func    = libDynamixel['set_nx_'..register]
    local mx_set_func = libDynamixel['set_mx_'..register]
    --
    local wr_values   = jcm['get_actuator_'..register]()
    --local is_writes   = jcm['get_write_'..register]()
    --
    -- Instantiate the commands for the chains
    for _,d in pairs(dynamixels) do
      local cmd_ids = {}
      local cmd_vals = {}
      for _,id in ipairs(d.nx_ids) do
        local idx = motor_to_joint[id]
        if is_writes[idx]>0 then
          is_writes[idx]=0
          table.insert(cmd_ids,id)
          if register=='command_position' then
            table.insert(cmd_vals,Body.make_joint_step(idx,wr_values[idx]))
          else
            table.insert(cmd_vals,wr_values[idx])
          end
        end
      end
      -- make the pkts
      if #cmd_ids>0 then
        --print('writing',register,'\n',vector.new(cmd_ids),'\n',vector.new(cmd_vals))
        table.insert(d.cmd_pkts, set_func(cmd_ids,cmd_vals) )
      end
      --
    end
    --
  end
  --
  for register,is_reads in pairs(jcm.readPtr) do

    if register=='lfoot' then
      if is_reads[1]>0 then
        is_reads[1]=0
        local d = motor_dynamixels[24]
        table.insert(d.read_pkts,{
          libDynamixel.get_nx_data{24,26},
          'lfoot'})
        d.n_expect_read = d.n_expect_read + 2
      end
    elseif register=='rfoot' then
      if is_reads[1]>0 then
        is_reads[1]=0
        local d = motor_dynamixels[23]
        table.insert(d.read_pkts,{
          libDynamixel.get_nx_data{23,25},
          'rfoot'})
        d.n_expect_read = d.n_expect_read + 2
      end
    else
      local get_func    = libDynamixel['get_nx_'..register]
      local mx_get_func = libDynamixel['get_mx_'..register]
      --local is_reads    = jcm['get_read_'..register]()
      --util.ptable(dynamixels)
      for _,d in pairs(dynamixels) do
        local read_ids = {}
        for _,id in ipairs(d.nx_ids) do
          local idx = motor_to_joint[id]
          --
          if is_reads[idx]>0 then
            is_reads[idx]=0
            table.insert(read_ids,id)
          end
        end
        -- mk pkt
        if #read_ids>0 then
          --print('mk',register)
          table.insert(d.read_pkts,{get_func(read_ids),register})
          d.n_expect_read = d.n_expect_read + #read_ids
        end
      end
    end
  end

  -- Execute packet sending
  -- Send the commands first
  ----[[
  local done = true
  repeat -- round robin repeat
    done = true
    for _,d in pairs(dynamixels) do
      local fd = d.fd
      -- grab a packet
      local pkt = table.remove(d.cmd_pkts)
      -- ensure that the pkt exists
      if pkt then
        -- remove leftover reads
        --local leftovers = unix.read(fd)
        -- flush previous writes
        local flush_ret = stty.flush(fd)
        -- write the new command
        local cmd_ret = unix.write( fd, pkt )
        -- possibly need a drain? Robotis does not
        local flush_ret = stty.drain(fd)
        local t_cmd  = unix.time()
        d.t_diff_cmd = t_cmd - d.t_cmd
        d.t_cmd      = t_cmd
        --print('tdiff_cmd',d.ttyname,d.t_diff_cmd*1000)
        -- check if now done
        if #d.cmd_pkts>0 then
          unix.usleep(1e3)
          done = false
        end
      end
    end
  until done
  --]]

----[[
  -- Send the requests next
  local done = true
  repeat -- round robin repeat
    done = true
    for _,d in pairs(dynamixels) do
      local fd = d.fd
      d.str = ''
      -- grab a packet
      local pkt = table.remove(d.read_pkts)
      -- ensure that the pkt exists
      if pkt then
        d.read_register = pkt[2]
        -- flush previous stuff
        local flush_ret = stty.flush(fd)
        -- write the new command
        local t_write = unix.time()
        local cmd_ret = unix.write( fd, pkt[1] )
        -- possibly need a drain? Robotis does not
        local flush_ret = stty.drain(fd)
        -- check if now done
        if #d.cmd_pkts>0 then done = false end
      end
    end
    -- Await the responses of these packets
    local READ_TIMEOUT = 12e-3 --8ms
    local still_recv = true
    while still_recv do
      still_recv = false
      local status, ready = unix.select(dynamixel_fds,READ_TIMEOUT)
      -- if a timeout, then return
      if status==0 then print('read timeout') break end
      for ready_fd, is_ready in pairs(ready) do
        -- for items that are ready
        if is_ready then
          still_recv = process_fd(ready_fd)
        end
      end -- for each ready_fd
    end
  until done
--]]
end
Body.exit = function()
  for k,d in pairs(dynamixels) do
    -- Torque off motors
    libDynamixel.set_nx_torque_enable( d.nx_ids, 0, d )
    if d.mx_ids then
      libDynamixel.set_mx_torque_enable( d.mx_ids, 0, d )
    end
    -- Close the fd
    d:close()
    -- Print helpful message
    print('Closed',k)
  end
  -- close imu
  microstrain:ahrs_off()
  microstrain:close()
end


function init_status_feedback()
  feedback_udp_ch = udp.new_sender(Config.net.operator.wired,Config.net.feedback)
  print('Connected to Operator:',
    Config.net.operator.wired,Config.net.feedback)
end

--SJ: we need to consolidate status feedback somewhere
local function send_status_feedback()
  local data={};
  data.larmangle = Body.get_larm_command_position()
  data.rarmangle = Body.get_rarm_command_position()
  data.waistangle = Body.get_waist_command_position()
  data.neckangle = Body.get_head_command_position()
  data.llegangle = Body.get_lleg_command_position()
  data.rlegangle = Body.get_rleg_command_position()
  data.lgrip =  Body.get_lgrip_command_position()
  data.rgrip =  Body.get_rgrip_command_position()

  --Pose information
  data.pose =  {0,0,0}
  data.pose_odom =  wcm.get_robot_pose_odom()
  data.pose_slam =  wcm.get_slam_pose()
  data.rpy = Body.get_sensor_rpy()
  data.body_height = mcm.get_camera_bodyHeight()
  data.battery =  0

  local datapacked = mp.pack(data);
  
  local ret,err = feedback_udp_ch:send( datapacked)
  if err then print('feedback udp',err) end
end
init_status_feedback()


----------------------
-- Webots compatibility
if IS_WEBOTS then
  -- TODO: fix the min/max/bias for the grippers
  local Config     = require'Config'
	local webots     = require'webots'
  local simple_ipc = require'simple_ipc'  
  local jpeg       = require'jpeg'  
  local png        = require'png'
  get_time    = webots.wb_robot_get_time
  local t_last_keypressed = get_time()
  -- Setup the webots tags
  local tags = {}

  servo.direction = vector.new({
    1,-1, -- Head
--    1,-1,-1,1,-1,1,-1, --LArm
    1,-1,-1,1,-1,-1,-1, --LArm    
    -- TODO: No legs yet!
    -1,-1,-1,-1,1,1, --LLeg
    -1,-1,1,1,-1,1, --LArm
--    -1,-1,-1,-1,-1,1,-1, --RArm
      -1,-1,-1,-1,-1,-1,-1, --RArm    
    -- TODO: Check the gripper
    1,1, -- Waist
--  -1,1,-1, -- left gripper
    1,-1,-1, -- left gripper    
    -1,1,1, -- right gripper

    1, -- Lidar pan
  })
  servo.rad_bias = vector.new({
    0,0, -- head
    -90,-10,0,45,0,0,0,
    0,0,0,0,0,0,
    0,0,0,0,0,0,
    -90,10,0,45,0,0,0,
    0,0,
    --SJ: default is closed for fingers(webots)
    -90,-90,-90,
    -90,-90,-90,
    60,--30,
  })*DEG_TO_RAD
  
  servo.min_rad = vector.new({
    -90,-80, -- Head

    -90, 0, -90, -160,      -180,-87,-180, --LArm
    -175,-175,-175,-175,-175,-175, --LLeg
    -175,-175,-175,-175,-175,-175, --RLeg
    -90,-87,-90,-160,       -180,-87,-180, --RArm

    -90,-45, -- Waist

    45,45,45, -- left gripper
    45,45,45, -- right gripper

    -60, -- Lidar pan
  })*DEG_TO_RAD
  
  servo.max_rad = vector.new({
    90, 80, -- Head

    160,87,90,-25,     180,87,180, --LArm
    175,175,175,175,175,175, --LLeg
    175,175,175,175,175,175, --RLeg
    160,-0,90,-25,     180,87,180, --RArm

    90,45, -- Waist
    80,80,80,
    80,80,80,    
   
    60, -- Lidar pan
  })*DEG_TO_RAD
  
  -- Webots body broadcasting
  local chest_lidar_wbt, head_lidar_wbt
  head_lidar_wbt = {}
  head_lidar_wbt.meta = {}
  head_lidar_wbt.channel  = simple_ipc.new_publisher'head_lidar'
  chest_lidar_wbt = {}
  chest_lidar_wbt.meta = {}
  chest_lidar_wbt.channel = simple_ipc.new_publisher'chest_lidar'

  local head_camera_wbt, update_head_camera
  -- camera
  head_camera_wbt = {}
  head_camera_wbt.meta = {}
  --head_camera_wbt.channel = simple_ipc.new_publisher'head_cam'
  head_camera_wbt.channel = udp.new_sender(Config.net.operator.wired,Config.net.head_camera)
  update_head_camera = function()  
    local metadata = {}
    metadata.t = Body.get_time()
    local net_settings = vcm.get_head_camera_net()
    if net_settings[1]==0 then return end
    local c_color
    if net_settings[2]==1 then
      metadata.c = 'jpeg'
      c_color = jpeg.compress_rgb(
        webots.to_rgb(tags.head_camera),
        head_camera_wbt.width,
        head_camera_wbt.height)
      metadata.width = head_camera_wbt.width
      metadata.height = head_camera_wbt.height
    elseif net_settings[2]==2 then
      metadata.c = 'png'
      c_color = png.compress(
        webots.to_rgb(tags.head_camera),
        head_camera_wbt.width,
        head_camera_wbt.height)
      metadata.width = head_camera_wbt.width
      metadata.height = head_camera_wbt.height
    end
    if not c_color then return end
    local metapack = mp.pack(metadata)
    local ret_c,err_c = head_camera_wbt.channel:send( metapack..c_color )

    if err_c then print('head cam',util.color(err_c,'red')) end
    if net_settings[1]==1 then
      net_settings[1] = 0
      vcm.set_head_camera_net(net_settings)
      return
    end
  end --update_head_camera
  
  
    local timeStep = webots.wb_robot_get_basic_time_step()

--    local lidar_timeStep = 25
--    local camera_timeStep = 33
  -- Lidar and camera timestep should be SLOWER than the webots timestep
  local lidar_timeStep = math.max(25, timeStep)
  local camera_timeStep = math.max(33,timeStep)

	Body.entry = function()
    
    -- Request @ t=0 to always be earlier than position reads
    jcm.set_trequest_position( vector.zeros(nJoint) )

		-- Initialize the webots system
		webots.wb_robot_init()

		-- Grab the update time
		
    local timeStep = webots.wb_robot_get_basic_time_step()

    -- Enable the keyboard 100ms
    webots.wb_robot_keyboard_enable( 100 )

		-- Grab the tags from the joint names
		tags.joints = {}
		for i,v in ipairs(jointNames) do
			tags.joints[i] = webots.wb_robot_get_device(v)
			if tags.joints[i]>0 then
				webots.wb_servo_enable_position(tags.joints[i], timeStep)
			else
				print(v,'not found')
			end
		end


    tags.passive_joints = {}
    for i,v in ipairs(passiveJointNames) do
      tags.passive_joints[i] = webots.wb_robot_get_device(v)
      if tags.passive_joints[i]>0 then
        webots.wb_servo_enable_position(tags.passive_joints[i], timeStep)
      else
        print(v,'not found')
      end
    end


		-- Add Sensor Tags
		-- Accelerometer
		tags.accelerometer = webots.wb_robot_get_device("Accelerometer")
		webots.wb_accelerometer_enable(tags.accelerometer, timeStep)
		-- Gyro
		tags.gyro = webots.wb_robot_get_device("Gyro")
		webots.wb_gyro_enable(tags.gyro, timeStep)
    -- Perfect Pose
    if use_pose then
      -- GPS
		  tags.gps = webots.wb_robot_get_device("GPS")
		  webots.wb_gps_enable(tags.gps, timeStep)
		  -- Compass
		  tags.compass = webots.wb_robot_get_device("Compass")
		  webots.wb_compass_enable(tags.compass, timeStep)
      -- RPY
      tags.inertialunit = webots.wb_robot_get_device("InertialUnit")
      webots.wb_inertial_unit_enable(tags.inertialunit, timeStep)
    end
    --[[
		-- Kinect
		tags.kinect = webots.wb_robot_get_device("kinect")
		webots.wb_camera_enable(tags.kinect, timeStep)
		--]]
    -- Head Camera
    tags.head_camera = webots.wb_robot_get_device("Camera")
    -- Chest Lidar
    tags.chest_lidar = webots.wb_robot_get_device("ChestLidar")
    chest_lidar_wbt.meta.count = 0
    -- Head Lidar
    tags.head_lidar  = webots.wb_robot_get_device("HeadLidar")
    head_lidar_wbt.meta.count = 0
    if use_lidar_chest then
      webots.wb_camera_enable(tags.chest_lidar, lidar_timeStep)            
      chest_lidar_wbt.pointer = webots.wb_camera_get_range_image(tags.chest_lidar)
    end
    if use_lidar_head then      
      webots.wb_camera_enable(tags.head_lidar, lidar_timeStep)
      head_lidar_wbt.pointer  = webots.wb_camera_get_range_image(tags.head_lidar)      
    end
    if use_camera then
      webots.wb_camera_enable(tags.head_camera, camera_timeStep)
      head_camera_wbt.meta.count = 0
      head_camera_wbt.width = webots.wb_camera_get_width(tags.head_camera)
      head_camera_wbt.height = webots.wb_camera_get_height(tags.head_camera)
    end

--[[
    --FSR sensors
    tags.l_ul_fsr = webots.wb_robot_get_device("L_UL_FSR")
    tags.l_ur_fsr = webots.wb_robot_get_device("L_UR_FSR")
    tags.l_ll_fsr = webots.wb_robot_get_device("L_LL_FSR")    
    tags.l_lr_fsr = webots.wb_robot_get_device("L_LR_FSR")    

    webots.wb_touch_sensor_enable(tags.l_ul_fsr, timeStep)
    webots.wb_touch_sensor_enable(tags.l_ur_fsr, timeStep)
    webots.wb_touch_sensor_enable(tags.l_ll_fsr, timeStep)
    webots.wb_touch_sensor_enable(tags.l_lr_fsr, timeStep)

    tags.r_ul_fsr = webots.wb_robot_get_device("R_UL_FSR")
    tags.r_ur_fsr = webots.wb_robot_get_device("R_UR_FSR")
    tags.r_ll_fsr = webots.wb_robot_get_device("R_LL_FSR")    
    tags.r_lr_fsr = webots.wb_robot_get_device("R_LR_FSR")    

    webots.wb_touch_sensor_enable(tags.r_ul_fsr, timeStep)
    webots.wb_touch_sensor_enable(tags.r_ur_fsr, timeStep)
    webots.wb_touch_sensor_enable(tags.r_ll_fsr, timeStep)
    webots.wb_touch_sensor_enable(tags.r_lr_fsr, timeStep)


--]]
    tags.l_fsr = webots.wb_robot_get_device("L_FSR")
    tags.r_fsr = webots.wb_robot_get_device("R_FSR")
    webots.wb_touch_sensor_enable(tags.l_fsr, timeStep)
    webots.wb_touch_sensor_enable(tags.r_fsr, timeStep)

		-- Take a step to get some values
		webots.wb_robot_step(timeStep)
		Body.timeStep = timeStep
		-- Filter the IMU a bit?
		-- TODO: Should use Yida's IMU filter
		--imuAngle = {0, 0, 0}
		--aImuFilter = 1 - math.exp(-tDelta/0.5)

    for idx, jtag in ipairs(tags.joints) do
      if jtag>0 then
        local val = webots.wb_servo_get_position( jtag )
        local rad = servo.direction[idx] * val - servo.rad_bias[idx]
        jcm.sensorPtr.position[idx] = rad
        jcm.actuatorPtr.command_position[idx] = rad
        jcm.treadPtr.position[idx] = t
        jcm.twritePtr.command_position[idx] = t
      end
    end

	end
	Body.update = function()

    local t = Body.get_time()

		local tDelta = .001 * Body.timeStep
		-- Set actuator commands from shared memory
		for idx, jtag in ipairs(tags.joints) do
			local cmd = Body.get_actuator_command_position(idx)
			local pos = Body.get_sensor_position(idx)
			-- TODO: What is velocity?
			local vel = 0 or Body.get_actuator_command_velocity(idx)
			local en  = 1 or Body.get_actuator_torque_enable(idx)
			local deltaMax = tDelta * vel
			-- Only update the joint if the motor is torqued on

			-- If the joint is moving
			-- Clamp the difference between commanded and actuated
			-- so that we don't have huge jumped
			-- NOTE: This *should* be handled by the simulator?
			local new_pos = cmd
			if vel > 0 then
				local delta = cmd - pos
				if delta > deltaMax then
					delta = deltaMax
				elseif delta < -deltaMax then
					delta = -deltaMax
				end
				new_pos = pos + delta
			end

			-- Only set in webots if Torque Enabled
			if en>0 and jtag>0 then
        local pos = servo.direction[idx] * (new_pos + servo.rad_bias[idx])
        --SJ: Webots is STUPID so we should set direction correctly to prevent flip
        local val = webots.wb_servo_get_position( jtag )

        if pos>val+math.pi then 
          webots.wb_servo_set_position(jtag, pos-2*math.pi )
        elseif pos<val-math.pi then
          webots.wb_servo_set_position(jtag, pos+2*math.pi )
        else
          webots.wb_servo_set_position(jtag, pos )
        end
        jcm.twritePtr.command_position[idx] = t
      end
		end --for

		-- Step the simulation, and shutdown if the update fails
		if webots.wb_robot_step(Body.timeStep) < 0 then os.exit() end

		-- Accelerometer data (verified)
		local accel = webots.wb_accelerometer_get_values(tags.accelerometer)
    jcm.sensorPtr.accelerometer[1] = (accel[1]-512)/128
    jcm.sensorPtr.accelerometer[2] = (accel[2]-512)/128
    jcm.sensorPtr.accelerometer[3] = (accel[3]-512)/128

		-- Gyro data (verified)
		local gyro = webots.wb_gyro_get_values(tags.gyro)

    jcm.sensorPtr.gyro[1] = -(gyro[1]-512)/512*39.24
    jcm.sensorPtr.gyro[2] = -(gyro[2]-512)/512*39.24
    jcm.sensorPtr.gyro[3] = (gyro[3]-512)/512*39.24

    -- FSR forces
    --[[
    jcm.sensorPtr.lfoot[1] = webots.wb_touch_sensor_get_value(tags.l_ul_fsr)
    jcm.sensorPtr.lfoot[2] = webots.wb_touch_sensor_get_value(tags.l_ur_fsr)
    jcm.sensorPtr.lfoot[3] = webots.wb_touch_sensor_get_value(tags.l_ll_fsr)
    jcm.sensorPtr.lfoot[4] = webots.wb_touch_sensor_get_value(tags.l_lr_fsr)
    --
    jcm.sensorPtr.rfoot[1] = webots.wb_touch_sensor_get_value(tags.r_ul_fsr)
    jcm.sensorPtr.rfoot[2] = webots.wb_touch_sensor_get_value(tags.r_ur_fsr)
    jcm.sensorPtr.rfoot[3] = webots.wb_touch_sensor_get_value(tags.r_ll_fsr)
    jcm.sensorPtr.rfoot[4] = webots.wb_touch_sensor_get_value(tags.r_lr_fsr)
    --]]

    jcm.sensorPtr.lfoot[1] = webots.wb_touch_sensor_get_value(tags.l_fsr)*4
    
    --
    jcm.sensorPtr.rfoot[1] = webots.wb_touch_sensor_get_value(tags.r_fsr)*4
    

    --Passive joint handling (2nd digit for figners)    
    local passive_jangle_offsets = {
      math.pi/4,-math.pi/4,-math.pi/4,-math.pi/4,math.pi/4,math.pi/4
    }
    local passive_jangle_factor = 1.3;
    for i=1,6 do
      local ang_orig = webots.wb_servo_get_position(tags.joints[i+Body.indexLGrip-1])
      webots.wb_servo_set_position(tags.passive_joints[i],
        (ang_orig + passive_jangle_offsets[i]) * passive_jangle_factor  )
    end

--[[
    print("FSRL:",unpack(jcm.get_sensor_lfoot()))
    print("FSRR:",unpack(jcm.get_sensor_rfoot()))
 --]]


    -- Debugging:
    --print('Gyro:',Body.get_sensor_gyro())
    --print('Accel:',Body.get_sensor_accelerometer())

    -- GPS and compass data
    -- Webots x is our y, Webots y is our z, Webots z is our x, 
    -- Our x is Webots z, Our y is Webots x, Our z is Webots y
    if use_pose then
      local gps     = webots.wb_gps_get_values(tags.gps)
      local compass = webots.wb_compass_get_values(tags.compass)
      local angle   = math.atan2( compass[3], compass[1] )
      local pose    = vector.pose{gps[3], gps[1], angle}
      wcm.set_robot_pose( pose )
      local rpy = webots.wb_inertial_unit_get_roll_pitch_yaw(tags.inertialunit)

      --SJ: we need to remap rpy for webots
      jcm.sensorPtr.rpy[1],jcm.sensorPtr.rpy[2],jcm.sensorPtr.rpy[3] = 
        rpy[2],rpy[1],-rpy[3]

      --[[
      print('rpy',unpack(rpy) )
      print('gps',unpack(gps) )
      print('compass',unpack(compass) )
      print('pose', pose )
      print()
      --]]
    end

    if use_joint_feedback then
      send_status_feedback() --for webots, just send every frame
    end

		-- Update the sensor readings of the joint positions
		-- TODO: If a joint is not found?
		for idx, jtag in ipairs(tags.joints) do
			if jtag>0 then
				local val = webots.wb_servo_get_position( jtag )
				local rad = servo.direction[idx] * val - servo.rad_bias[idx]
        jcm.sensorPtr.position[idx] = rad
        jcm.treadPtr.position[idx] = t
			end
		end
    
    -- Set lidar data into shared memory
    if use_lidar_head then
      Body.set_head_lidar(head_lidar_wbt.pointer)

      head_lidar_wbt.meta.t  = t
      head_lidar_wbt.meta.count  = head_lidar_wbt.meta.count  + 1
      head_lidar_wbt.meta.hangle = Body.get_head_position()
      head_lidar_wbt.meta.rpy  = Body.get_sensor_rpy()
      head_lidar_wbt.meta.gyro = Body.get_sensor_gyro()
      -- Send the count on the channel so they know to process a new frame
      head_lidar_wbt.channel:send(  mp.pack(head_lidar_wbt.meta)  )
    end
    if use_lidar_chest then
      Body.set_chest_lidar(chest_lidar_wbt.pointer)
      -- Save important metadata
      chest_lidar_wbt.meta.t  = t
      chest_lidar_wbt.meta.count = chest_lidar_wbt.meta.count + 1
      chest_lidar_wbt.meta.pangle = Body.get_lidar_position(1)
      chest_lidar_wbt.meta.rpy  = Body.get_sensor_rpy()
      chest_lidar_wbt.meta.gyro = Body.get_sensor_gyro()
      -- Send the count on the channel so they know to process a new frame
      chest_lidar_wbt.channel:send( mp.pack(chest_lidar_wbt.meta) )
    end
    if use_camera then
      update_head_camera()
    end --use_camera

    -- Grab keyboard input
    local key_code = webots.wb_robot_keyboard_get_key()
    local key_char = string.char(key_code)
    local key_char_lower = string.lower(key_char)

    --avoid auto-repeat
    local t = get_time()
    if (t-t_last_keypressed)<1 then return end

    if key_char_lower=='k' then
      t_last_keypressed = t
      use_lidar_head = not use_lidar_head
      -- Toggle lidar
      if use_lidar_head then
        print(util.color('HEAD LIDAR enabled!','yellow'))        
        webots.wb_camera_enable(tags.head_lidar, lidar_timeStep)
        head_lidar_wbt.pointer  = webots.wb_camera_get_range_image(tags.head_lidar)        
      else
        print(util.color('HEAD LIDAR disabled!','yellow'))        
        webots.wb_camera_disable(tags.head_lidar)
      end
    elseif key_char_lower=='l' then
      t_last_keypressed = t
      use_lidar_chest = not use_lidar_chest
      -- Toggle lidar
      if use_lidar_chest then
        print(util.color('CHEST LIDAR enabled!','yellow'))
        webots.wb_camera_enable(tags.chest_lidar, lidar_timeStep)
        chest_lidar_wbt.pointer = webots.wb_camera_get_range_image(tags.chest_lidar)
      else
        print(util.color('CHEST LIDAR disabled!','yellow'))
        webots.wb_camera_disable(tags.chest_lidar)        
      end
    elseif key_char_lower=='c' then
      t_last_keypressed = t
      use_camera = not use_camera
      -- Toggle camera
      if use_camera then
        print(util.color('Camera enabled!','yellow'))
        vcm.set_head_camera_net({2,1,0})--to enable camera streaming
        webots.wb_camera_enable(tags.head_camera, camera_timeStep)
      else
        print(util.color('Camera disabled!','yellow'))
        vcm.set_head_camera_net({0,0,0})--to enable camera streaming
        webots.wb_camera_disable(tags.head_camera)
      end
    elseif key_char_lower=='j' then
      t_last_keypressed = t
      use_joint_feedback = not use_joint_feedback
      -- Toggle camera
      if use_joint_feedback then
        print(util.color('Joint feedback enabled!','yellow'))                
      else
        print(util.color('Joint feedback disabled!','yellow'))                        
      end
    end
	end -- function

	Body.exit = function()
	end
	Body.tags = tags

  --Touchdown check for webots
  --Use FSR sensors

  local FSR_threshold = 200
  Body.get_lfoot_touched = function()
    local LFSR = jcm.get-sensor_lfoot()  
    if (LFSR[1]+LFSR[2]+LFSR[3]+LFSR[4])>FSR_threshold then
      return true
    else
      return false
    end
  end
  Body.get_rfoot_touched = function()
    local RFSR = jcm.get-sensor_rfoot()    
    if (RFSR[1]+RFSR[2]+RFSR[3]+RFSR[4])>FSR_threshold then
      return true
    else
      return false
    end
  end
else -- webots check
  --Touchdown check for actual robot
  --Force torque sensor based
  Body.get_lfoot_touched = function()
    return false 
  end
  Body.get_rfoot_touched = function()
    return false 
  end
end 

-- Exports for use in other functions
Body.get_time = get_time
-- Real THOR-OP (Cenatur uses ankles for wheels, maybe?)
Body.indexHead = indexHead   -- Head: 1 2
Body.nJointHead = nJointHead
Body.indexLArm = indexLArm   --LArm: 5 6 7 8 9 10
Body.nJointLArm = nJointLArm 		
Body.indexLLeg = indexLLeg  --LLeg: 11 12 13 14 15 16
Body.nJointLLeg = nJointLLeg
Body.indexRLeg = indexRLeg  --RLeg: 17 18 19 20 21 22
Body.nJointRLeg = nJointRLeg
Body.indexRArm = indexRArm  --RArm: 23 24 25 26 27 28
Body.nJointRArm = nJointRArm
Body.indexWaist = indexWaist  --Waist: 3 4
Body.nJointWaist = nJointWaist
-- 6 Fingers for gripping
-- 1 servo for lidar panning
Body.indexLGrip = indexLGrip
Body.nLGrip = nLGrip
Body.indexRGrip = indexRGrip
Body.nRGrip = nRGrip
Body.indexLidar = indexLidar
Body.nJointLidar = nJointLidar
Body.nJoint = nJoint
Body.jointNames = jointNames
Body.parts = parts
Body.inv_parts = inv_parts
Body.motor_parts = motor_parts
Body.servo = servo
Body.make_joint_step = make_joint_step
Body.make_joint_radian = make_joint_radian

Body.Kinematics = Kinematics

-- For supporting the THOR repo
require'mcm'
Body.set_walk_velocity = function(vel)
  mcm.set_walk_vel(vel)
end

Body.init_odometry = function(uTorso)
  wcm.set_robot_utorso0(uTorso)
  wcm.set_robot_utorso1(uTorso)  
end

--This function should be called by motion state
Body.update_odometry = function(uTorso)
  local uTorso1 = wcm.get_robot_utorso1()  

  --update odometry pose  
  local odometry_step = util.pose_relative(uTorso,uTorso1)
  local pose_odom0 = wcm.get_robot_pose_odom()
  local pose_odom = util.pose_global(odometry_step, pose_odom0)
  wcm.set_robot_pose_odom(pose_odom)

  --updae odometry variable
  wcm.set_robot_utorso1(uTorso)
end

--This function should be called by slam wizard (slower rate than state update)
Body.get_odometry = function()
  local uTorso0 = wcm.get_robot_utorso0()
  local uTorso1 = wcm.get_robot_utorso1()  

  wcm.set_robot_utorso0(uTorso0) --reset initial position
  return util.pose_relative(uTorso1,uTorso0)
end

return Body