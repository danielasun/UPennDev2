#!/usr/bin/env luajit
-- (c) 2014 Team THORwIn
pcall(dofile,'fiddle.lua')
pcall(dofile, '../fiddle.lua')
local WAS_REQUIRED = ... and type(...)=='string'
-- Look up tables
local code_lut, char_lut, lower_lut = {}, {}, {}
-- 
char_lut['1'] = function()
  motion_ch:send'stand'
	arm_ch:send'init'
end
lower_lut['l'] = function()
  motion_ch:send'lean'
end
lower_lut['u'] = function()
  motion_ch:send'stepup'
end
lower_lut['d'] = function()
  motion_ch:send'stepdown'
end
lower_lut['s'] = function()
  motion_ch:send'sway'
end
lower_lut['q'] = function()
  motion_ch:send'quit'
end
-- Arm stuff
lower_lut['r'] = function()
  arm_ch:send'ready'
end

local function show_status()
  if not IS_WEBOTS then os.execute('clear') end
  print(util.color('Teach a bot', 'magenta'))
end

local function update(key_code)
  -- Assure that we got a character
  if type(key_code)~='number' or key_code==0 then return end
	local key_char = string.char(key_code)
	local key_char_lower = string.lower(key_char)
  
  local code_f, char_f, lower_f = code_lut[key_code], char_lut[key_char], lower_lut[key_char_lower]
  -- Precedence
  if type(code_f)=='function' then
    code_f()
  elseif type(char_f)=='function' then
    char_f()
  elseif type(lower_f)=='function' then
    lower_f()
  end
	show_status()
end

-- Show the initial status
show_status()

if WAS_REQUIRED then return {entry=nil, update=update, exit=nil} end

print("Game role:",gcm.get_game_role())
print("Game state:",gcm.get_game_state())

local getch = require'getch'
local running = true
local key_code
while running do
	key_code = getch.block()
  update(key_code)
end