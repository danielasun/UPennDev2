local state = {}
state._NAME = ...
local Body = require'Body'
local vector = require'vector'
local plugins = require'armPlugins'
local movearm = require'movearm'
local t_entry, t_update, t_finish
local timeout = 30.0

local piterators, ok
local lPathIter, rPathIter
local qLD, qRD
local uTorsoComp, uTorso0
local qLGoalFiltered, qRGoalFiltered

function state.entry()
  print(state._NAME..' Entry')
  local t_entry_prev = t_entry
  t_entry = Body.get_time()
  t_update = t_entry

	local pull_door = plugins.gen'pull_door'
  local m ={}
  m.x = .45
  m.y = -.4
  m.z = 0
  m.yaw = 0
  m.hinge = -1
  m.roll = -math.pi/2
	m.hand = 'right'
	piterators = movearm.model_iterators(pull_door, m)

end

function state.update()
--  print(state._NAME..' Update' )
  local t  = Body.get_time()
  local dt = t - t_update
  t_update = t
  if t-t_entry > timeout then return'timeout' end

	if not lPathIter or not rPathIter then
		if coroutine.status(piterators)=='dead' then
			return'done'
		end
		ok, lPathIter, rPathIter, qLGoalFiltered, qRGoalFiltered, qLD, qRD = coroutine.resume(piterators)
		if not ok then
			print(state._NAME, ok, lPathIter)
			return'done'
		end
		lPathIter = lPathIter or true
		rPathIter = rPathIter or true
	end

	local qcLArm = Body.get_larm_command_position()
	local qcRArm = Body.get_rarm_command_position()

	-- Find the next arm position
	local moreL, q_lWaypoint
	if type(lPathIter)=='function' then moreL, q_lWaypoint = lPathIter(qcLArm, dt) end
	local moreR, q_rWaypoint
	if type(rPathIter)=='function' then moreR, q_rWaypoint = rPathIter(qcRArm, dt) end
	local qLNext = moreL and q_lWaypoint or qLGoalFiltered
	local qRNext = moreR and q_rWaypoint or qRGoalFiltered

	-- Set the arm and torso commands
	if qLNext then Body.set_larm_command_position(qLNext) end
	if qRNext then Body.set_rarm_command_position(qRNext) end

	-- Check if done and reset the iterators
	if not moreL and not moreR then lPathIter, rPathIter = nil, nil end

end

function state.exit()
  print(state._NAME..' Exit' )
	local qcLArm = Body.get_larm_command_position()
	local qcRArm = Body.get_rarm_command_position()
	hcm.set_teleop_larm(qcLArm)
  hcm.set_teleop_rarm(qcRArm)
end

return state
