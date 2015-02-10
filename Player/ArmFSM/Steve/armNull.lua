local state = {}
state._NAME = ...

local torch = require'torch'
local Body = require'Body'
local K = require'K_ffi'
local util = require'util'
local t_entry, t_update, t_finish
local timeout = 10.0

-- Gain for moving the arm
local qCurGain = 1 / 7500
-- Count the current offset
local sample_cur
-- Count the directions
local sample_dir
-- Count the inflections
local n_inflections, is_inflected, was_inflected
-- Count the steady state
local n_steady_state
-- Detect the direction and current offset and the joint initially
local dir0, cur0, q0
-- Check if moving
local moving
-- Threholds
local cur_std
--
local qErr

-- The null degree of freedom
-- TODO: Use a jacbian and fun stuff
-- For now, just use the free parameter of the IK, which is just the third joint
local dof = 3

function state.entry()
  print(state._NAME..' Entry' )
  -- Update the time of entry
  local t_entry_prev = t_entry -- When entry was previously called
  t_entry = Body.get_time()
  t_update = t_entry
  t_finish = t
	--
	sample_cur = {}
	sample_dir = {}
  --
	n_inflections = 0
  is_inflected = false
  was_inflected = false
  --
	n_steady_state = 0
  --
	cur0 = false
	dir0 = false
	q0 = Body.get_rarm_command_position()[dof]
  -- error in the position (sag)
  qErr = Body.get_rarm_position()[dof] - q0
  print('qErr', qErr*RAD_TO_DEG)
  --
  cur_std = math.huge
  --
  moving = false
end

function state.update()
  --print(state._NAME..' Update' )
  -- Get the time of update
  local t  = Body.get_time()
  local dt = t - t_update
  -- Save this at the last update time
  t_update = t
--  if t-t_entry > timeout then return'timeout' end

	-- Grab our data
  local cur = Body.get_rarm_current()[dof]
  local qArm = Body.get_rarm_position()
  local q = qArm[dof]

	-- Estimate the sample_cur while in this limit
	if moving==false then
    -- Need 100 samples
    if #sample_cur < 100 then
      if math.abs(q-q0)*RAD_TO_DEG<0.02 then
        table.insert(sample_cur, cur)
  		end
      -- After inserting, check
      if #sample_cur < 100 then return end
      -- Get the statistics
      local s = torch.Tensor(sample_cur)
      cur0 = s:mean()
      -- Assign the threshold
      cur_std = math.max(s:std(), 3)
    end
    -- We are moving if outside twice our std dev
		if math.abs(cur-cur0) < 3*cur_std then return end
		moving = true
    print('Moving the arm!', cur, cur0, cur_std)
	end

	local dCur = cur - cur0
  local dq = q - q0
	-- Check the direction of the current and position
	local dirCur = util.sign(util.procFunc(dCur, cur_std, 1))
  local dirQ = util.sign(util.procFunc(dq, 0.02 * DEG_TO_RAD, 1))

  -- Need at least 5 points to sum
	if #sample_dir < 5 then
		print('dirCur', dirCur)
    table.insert(sample_dir, dirCur)
    if #sample_dir < 5 then return end
    local s = torch.Tensor(sample_dir)
    dir0 = util.sign(s:sum())
    if dir0==0 then return end
    print('dir0= '..dir0)
	end

  -- Check if an inflection occurred
	if dirCur~=dir0 then
		n_inflections = n_inflections + 1
	else
		n_inflections = n_inflections - 1
		n_inflections = math.max(0, n_inflections)
	end
  is_inflected = n_inflections > 5
  if is_inflected~=was_inflected then
    print('Inflection change', is_inflected)
  end
  was_inflected = is_inflected

	-- Don't return on inflection. Wait until steady state
	if math.abs(dq)*RAD_TO_DEG < 0.05 then
		n_steady_state = n_steady_state + 1
	else
		n_steady_state = n_steady_state - 1
	end
	if n_steady_state > 20 then
		print('Steady state')
		return'null'
	end

	-- Must only use our initial direction to react to the human
	-- Can just re-enter the state quickly on direction change
	if dirCur~=dir0 then
--    print('outlier dir', dCur, dir0)
    return
  end
	if is_inflected then return end
--print('dirQ', dirQ, dirCur)
  -- Calculate the new position to use for the arm
	local dqFromCur = qCurGain * dCur
--	print('dqFromCur', dqFromCur)
	dqFromCur = 0.005 * dir0
	--if true then return'null' end
  local q1 = q0 - dqFromCur
	if dir0==1 then
		io.write('dCur ', dCur, '\tdir0 ', dir0, '\tdirCur ', dirCur, '\n')
		io.write('dq* ', dqFromCur*RAD_TO_DEG, '\tdq ', dq*RAD_TO_DEG, '\n')
		io.write('q0 ', q0*RAD_TO_DEG, '\n')
		io.write('q1 ', q1*RAD_TO_DEG, '\tq ', q*RAD_TO_DEG, '\n')
		io.write('\n')
	end

  -- Set on the robot
  -- NOTE: THIS CAN BE DANGEROUS!
	----[[
	q0 = q1
	Body.set_rarm_command_position(q0, dof)
	--]]

  --[[
	q0 = q1
  local trArm = K.forward_rarm(qArm)
  -- Get the inverse using the new free dof parameter (shoulderYaw)
  local iqArm = K.inverse_rarm(trArm, qArm, q0)
  Body.set_rarm_command_position(iqArm)
	--]]

end

function state.exit()
  print(state._NAME..' Exit' )
end

return state
