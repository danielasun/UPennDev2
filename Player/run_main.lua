module(... or "", package.seeall)

require('unix');
require('main');

while 1 do 
  tDelay = 0.005*1E6;
  main.update();
  unix.usleep(tDelay);
end

