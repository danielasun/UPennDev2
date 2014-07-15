#!/usr/bin/env luajit -i
dofile'include.lua'

-- Important libraries in the global space
local libs = {
  'Config',
  'Body',
  'util',
  'vector',
  'torch',
  'udp',
  'ffi',
}

-- Load the libraries
for _,lib in ipairs(libs) do
  local ok, lib_tbl = pcall(require, lib)
  if ok then
    _G[lib] = lib_tbl
  else
    print("Failed to load", lib)
  end
end

mp = require'msgpack'
local si = require'simple_ipc'

-- Requester
print('REQ |',Config.net.robot.wired,Config.net.reliable_rpc)
local rpc_req =
  si.new_requester(Config.net.reliable_rpc,Config.net.robot.wired)
unix.usleep(1e5)

-- Publisher
print('PUB |',Config.net.robot.wired,Config.net.reliable_rpc2)
local rpc_pub =
  si.new_publisher(Config.net.reliable_rpc2,true,Config.net.robot.wired)
unix.usleep(1e5)

-- UDP
print('UDP |',Config.net.robot.wired,Config.net.unreliable_rpc)
local rpc_udp = udp.new_sender(Config.net.robot.wired,Config.net.unreliable_rpc)

-- FSM communicationg
fsm_chs = {}
local fsm_send = function(t,evt)
  local ret = rpc_req:send(mp.pack({fsm=t.fsm,evt=evt}))
end
for _,sm in ipairs(Config.fsm.enabled) do
  local fsm_name = sm..'FSM'
  table.insert(fsm_chs, fsm_name)
  _G[sm:lower()..'_ch'] = {fsm=fsm_name, send=fsm_send}
end

-- Shared memory
local shm_send = function(t,func)
  local tbl = {}
  tbl.shm = t.shm
  tbl.access = func
  
  return function(val)
		if val then tbl.val=val end
		local packed = mp.pack(tbl)
		----[[
		if val then
			-- Just PUB to the robot for shm set
			tbl.val=val
			local ret = rpc_pub:send(mp.pack(tbl))
			return
		end
		--]]
		-- Use REQ/REP to get data
		rpc_req:send(packed)
		local data = rpc_req:receive()
    local result = mp.unpack(data)
    if type(result)=='table' then return vector.new(result) end
    return result
  end
end

-- This should overwrite memory calls...
local listing = unix.readdir(HOME..'/Memory')
local shm_vars = {}
for _,mem in ipairs(listing) do
  local found, found_end = mem:find'cm'
  if found then
    local name = mem:sub(1,found_end)
    table.insert(shm_vars,name)
    _G[name] = setmetatable({shm=name},{__index=shm_send})
  end
end

print(util.color('FSM Channel', 'yellow'), table.concat(fsm_chs, ' '))
print(util.color('SHM access', 'blue'), table.concat(shm_vars, ' '))

if arg and arg[-1]=='-i' and jit then
  -- Interactive LuaJIT
  package.path = package.path..';'..HOME..'/Tools/iluajit/?.lua'
  dofile'Tools/iluajit/iluajit.lua'
end
