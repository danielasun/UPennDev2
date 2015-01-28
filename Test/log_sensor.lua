#!/usr/bin/env luajit
-- (c) 2014 Team THORwIn
local ok = pcall(dofile,'../fiddle.lua')
if not ok then dofile'fiddle.lua' end

local t_last = Body.get_time()
local tDelay = 0.005*1E6

local RAD_TO_DEG= 180/math.pi


local getch = require'getch'
local running = true
local key_code

local sformat = string.format

require'mcm'
require'hcm'

count = 0

while running do
	local forceZ = mcm.get_status_forceZ()
	local forceTotal = mcm.get_status_forceTotal()
	local uZMP = mcm.get_status_uZMP()
	local uZMPMeasured = mcm.get_status_uZMPMeasured()

	local LZMP = mcm.get_status_LZMP()
	local RZMP = mcm.get_status_RZMP()


	local aShiftX = mcm.get_walk_aShiftX()
	local aShiftY = mcm.get_walk_aShiftY()

  	local enable_balance = hcm.get_legdebug_enable_balance()


  	local angleShift = mcm.get_walk_angleShift()


	count = count + 1

	if count%10 ==0 then
		os.execute('clear')

		print(sformat("Balancing: P Knee %.1f Ankle %.1f / R hip %.1f ankle %.1f",
			RAD_TO_DEG*angleShift[3], RAD_TO_DEG*angleShift[1]  , RAD_TO_DEG*angleShift[4], RAD_TO_DEG*angleShift[2]))



		print(sformat("force Z: %d %d Total: %d %d",forceZ[1],forceZ[2],forceTotal[1],forceTotal[2]))
		print(sformat("uZMPTarget: %.1f %.1f / uZMP: %.1f %.1f",
			uZMP[1]*100, uZMP[2]*100, uZMPMeasured[1]*100,	uZMPMeasured[2]*100

			))
		print(sformat("ZMP err: L %.1f %.1f R %.1f %.1f cm",
			LZMP[1]*100, LZMP[2]*100,RZMP[1]*100, RZMP[2]*100))

		print(sformat("leg balancing: %d %d",enable_balance[1],enable_balance[2]))

		print(sformat("Foot angles: Left P%.1f R%.1f  Right P%.1f R%.1f",
			RAD_TO_DEG*aShiftX[1],RAD_TO_DEG*aShiftY[1],RAD_TO_DEG*aShiftX[2],RAD_TO_DEG*aShiftY[2]            
			))
	end

	unix.usleep(tDelay);

end