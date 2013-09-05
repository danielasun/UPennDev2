-- Use the fsm module
local fsm = require'fsm'

-- Require the needed states
local gameIdle = require'gameIdle'

-- Instantiate a new state machine with an initial state
-- This will be returned to the user
local sm = fsm.new( gameIdle )

local gameDoor  = require'gameDoor'
sm:add_state(gameDoor)

-- Setup the transistions for this FSM
sm:set_transition( gameIdle, 'door', gameDoor )
--
sm:set_transition( gameDoor, 'done', gameIdle )
sm:set_transition( gameDoor, 'door', gameDoor )

-- Setup the FSM object
local obj = {}
local util = require'util'
-- Simple IPC for remote state triggers
local simple_ipc = require'simple_ipc'
local evts = simple_ipc.new_subscriber(...,true)
obj._NAME = ...
obj.entry = function()
  sm:entry()
end
obj.update = function()
  -- Check for out of process events in non-blocking
  local event, has_more = evts:receive(true)
  if event then
  	print( util.color(obj._NAME..' Event:','green'),event)
  	sm:add_event(event)
  end
  sm:update()
end
obj.exit = function()
  sm:exit()
end

obj.sm = sm

return obj