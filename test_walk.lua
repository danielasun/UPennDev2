dofile'include.lua'

-- Important libraries in the global space
local libs = {
  'Config',
  'Body',
  'unix',
  'util',
  'vector',
  'torch',
  'getch',
  'msgpack'
}

-- Load the libraries
for _,lib in ipairs(libs) do _G[lib] = require(lib) end
if torch then torch.Tensor = torch.DoubleTensor end

-- FSM communicationg
local listing = unix.readdir(HOME..'/Player')
-- Add all FSM directories that are in Player
local simple_ipc = require'simple_ipc'
local fsm_ch_vars = {}
for _,sm in ipairs(listing) do
  local found = sm:find'FSM'
  if found then
    -- make GameFSM to game_ch
    local name = sm:sub(1,found-1):lower()..'_ch'
    table.insert(fsm_ch_vars,name)
    -- Put into the global space
    _G[name] = simple_ipc.new_publisher(sm,true)
  end
end

-- Shared memory
local listing = unix.readdir(HOME..'/Memory')
local shm_vars = {}
for _,mem in ipairs(listing) do
  local found, found_end = mem:find'cm'
  if found then
    local name = mem:sub(1,found_end)
    table.insert(shm_vars,name)
    require(name)
  end
end

-- RPC engine
rpc_ch = simple_ipc.new_requester(Config.net.reliable_rpc)

-- Mesh requester
mesh_req_ch = simple_ipc.new_requester(Config.net.reliable_mesh)

-- Useful constants
DEG_TO_RAD = Body.DEG_TO_RAD
RAD_TO_DEG = Body.RAD_TO_DEG

print( util.color('FSM Channel','yellow'), table.concat(fsm_ch_vars,' ') )
print( util.color('SHM access','blue'), table.concat(shm_vars,' ') )


local channels = {
  ['motion_ch'] = motion_ch,
  ['body_ch'] = body_ch,
  ['arm_ch'] = arm_ch,
}


-- Events for the FSMs
local char_to_event = {
  ['1'] = {'body_ch','init'},


  ['7'] = {'motion_ch','sit'},
  ['8'] = {'motion_ch','stand'},
  ['9'] = {'motion_ch','walk'},

  ['t'] = {'body_ch','stepover'},
  ['2'] = {'body_ch','stepplan'},
  ['3'] = {'body_ch','stepplan2'},
  ['4'] = {'body_ch','stepplan3'},
  ['5'] = {'body_ch','steptest'},
  ['6'] = {'body_ch','stepwiden'},

--  ['6'] = {'body_ch','follow'},


  --
  ['a'] = {'arm_ch','init'},
  ['s'] = {'arm_ch','reset'},
  ['r'] = {'arm_ch','smallvalvegrab'},
  --
  ['x'] = {'arm_ch','teleop'},
  --
  ['w'] = {'arm_ch','wheelgrab'},
  --
  ['d'] = {'arm_ch','doorgrab'},

  ['c'] = {'arm_ch','toolgrab'},
}

local char_to_vel = {
  ['i'] = vector.new({0.05, 0, 0}),
  [','] = vector.new({-.05, 0, 0}),
  ['h'] = vector.new({0, 0.025, 0}),
  [';'] = vector.new({0, -.025, 0}),
  ['j'] = vector.new({0, 0, 5})*math.pi/180,
  ['l'] = vector.new({0, 0, -5})*math.pi/180,
}

local char_to_wheel = {
  ['['] = -1*Body.DEG_TO_RAD,
  [']'] = 1*Body.DEG_TO_RAD,
}

local char_to_state = {
  ['='] = 1,
  ['-'] = -1,
}





local function send_command_to_ch(channel, cmd_string)
  -- Default case is to send the command and receive a reply
--  local ret   = channel:send(msgpack.pack(cmd))
--  local reply = channel:receive()
--  return msgpack.unpack(reply)
print(cmd_string)
  local ret   = channel:send(cmd_string)
  return
end



local walk_target_local = vector.new({0,0,0})

local function start_navigation()
  hcm.set_motion_waypoints(walk_target_local)
  hcm.set_motion_nwaypoints(1)
  hcm.set_motion_waypoint_frame(0) --Relative movement
  send_command_to_ch(channels['body_ch'],'follow')
end


local function process_character(key_code,key_char,key_char_lower)
  local cmd

  -- Send motion fsm events
  local event = char_to_event[key_char_lower]
  if event then
    print( event[1], util.color(event[2],'yellow') )    
    return send_command_to_ch(channels[event[1]],event[2])
  end

  if key_char_lower == " " then
    print("GO GO GO")
    start_navigation()
    walk_target_local = vector.new({0,0,0})  
  end

  if key_char_lower=='e' then --ESTOP!
    hcm.set_motion_estop(1)
  end


  -- Adjust the velocity
  -- Only used in direct teleop mode
  local vel_adjustment = char_to_vel[key_char_lower]
  if vel_adjustment then
    walk_target_local = walk_target_local + vel_adjustment
    print( util.color('Target movement:','yellow'), 

      walk_target_local[1],
      walk_target_local[2],
      walk_target_local[3]*180/math.pi

      )
    return
  elseif key_char_lower=='k' then
    print( util.color('Zero target movement','yellow'))
    walk_target_local = vector.new({0,0,0})    
    return
  end

  -- Adjust the wheel angle
  local wheel_adj = char_to_wheel[key_char_lower]
  if wheel_adj then
    print( util.color('Turn wheel','yellow'), wheel_adj )
    local turnAngle = hcm.get_wheel_turnangle() + wheel_adj
    hcm.set_wheel_turnangle(turnAngle)
    return
  elseif key_char_lower=='\\' then
    print( util.color('Center the wheel','yellow') )    
    hcm.set_wheel_turnangle(0)
    return
  end

  local state_adj = char_to_state[key_char_lower]
  if state_adj then
    print( util.color('State advance','yellow'), state_adj )
    hcm.set_state_proceed(state_adj)
    return
  end

end




------------
-- Start processing
--os.execute("clear")
io.flush()
local t0 = unix.time()
while true do
  
  -- Grab the keyboard character
  local key_code = getch.block()
  local key_char = string.char(key_code)
  local key_char_lower = string.lower(key_char)
  
  -- Process the character
  local msg = process_character(key_code,key_char,key_char_lower)
  
  -- Measure the timing
  local t = unix.time()
  local t_diff = t-t0
  t0 = t
  local fps = 1/t_diff
 
  -- Print is_debugging message
  if is_debug then
    print( string.format('\nKeyboard | Code: %d, Char: %s, Lower: %s',
    key_code,key_char,key_char_lower) )
    print('Response time:',t_diff)
  end
    
end
