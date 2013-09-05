cwd = os.getenv('PWD')
local init = require('init')
--
--local Config = require 'Config'
local unix = require('unix')
local getch = require('getch')
local Broadcast = require('Broadcast')
local vcm = require('vcm')

-- Do not wait for a carriage return
getch.enableblock(1);
unix.usleep(1E6*1.0);

local ncount = 30;
local imagecount = 0;
local t0 = unix.time();
local tUpdate = t0;

-- Broadcast the images at a lower rate than other data
local maxFPS = 40;
local imgFPS = 10;

local maxPeriod = 1.0 / maxFPS;
local imgRate = math.max( math.floor( maxFPS / imgFPS ), 1);
imgRate = 10
local broadcast_enable=0;

function update()
  -- Get a keypress
  local str=getch.get();
  if #str>0 then
    local byte=string.byte(str,1);
    if byte==string.byte("g") then	--Broadcast selection
      local mymod = 4;
      broadcast_enable = (broadcast_enable+1)%mymod;
      print("Broadcast:", broadcast_enable);
    end
  end
  vcm.set_camera_broadcast(broadcast_enable); 
  -- Always send non-image data
  Broadcast.update(broadcast_enable);
  Broadcast.update_img(broadcast_enable);    
  return true;
end


while true do
  -- Get the time before sending packets
  local tstart = unix.time();
  updated= update();
  -- Get time after sending packets
  tloop = unix.time() - tstart;  -- Sleep in order to get the right FPS
  if (tloop < maxPeriod) then
    unix.usleep((maxPeriod - tloop)*(1E6));
  end

  -- Display our FPS and broadcast level
--  if (updated and imagecount % ncount == 0) then
--    print('fps: '..(ncount / (tstart - tUpdate))..', Level: '..broadcast_enable );
--    tUpdate = unix.time();
--  end

end