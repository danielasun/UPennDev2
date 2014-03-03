dofile'include.lua'
require'unix'
mp = require'msgpack'
util = require'util'
fname = 'load.log'

local do_log = true

local header_ns

local function get_net()
	local ns = io.popen'netstat -i'
	ns:read()
	local nsh = ns:read()
	if not header_ns then
		header_ns = {}
		local h = nsh:gmatch('%S+')
		local idx = 1
		for v in h do
			header_ns[v] = idx
			idx = idx+1
		end
		--	util.ptable(header_ns)
	end

	local rx0,tx0
	while true do
		local d = ns:read()
		if not d then break end
		if d:find('eth2%s+') then
			local dd = d:gmatch('%S+')
			local tmp = {}
			for v in dd do table.insert(tmp,v) end
			rx0 = tmp[header_ns['RX-OK']]
			tx0 = tmp[header_ns['TX-OK']]
			break
		end
	end
	return rx0,tx0
end


local function log()
	local rx0, tx0 = get_net()
	local lut = {}

	local ntimes = 200
	local rate = 0.5
	local top_cmd = 'top -b -d '..rate..' -n '..ntimes
	local pids = io.popen'ps h -C lua -o cmd,pid'
	while true do
		local pid = pids:read()
		if not pid then break end
		local process = pid:gmatch('lua (%S*)_wizard%.lua%s*(%d+)')
		local a,b = process()
		lut[b] = a
		top_cmd = top_cmd..' -p'..b
	end
	--print(top_cmd)

	local fl = io.open('load.log','w')
	fl:write(mp.pack(top_cmd))
	fl:write(mp.pack(lut))
	local top = io.popen(top_cmd)
	local header
	local data
	local count = 0
	while true do
		local x = top:read()
		if not x then break end
		--print(x)
		-- Check if new cycle
		local new_cycle = false
		if x:find'top'==1 then
			count = count + 1
			print('Count',count,'of',ntimes)
			-- Write the last log
			if data then
				--util.ptable(data)
				--util.ptable(data.lidar)
				fl:write(mp.pack(data))
			end
			local rx, tx = get_net()
			data = {t=unix.time(),n=count,rx=rx-rx0,tx=tx-tx0}
			--print('top',x)
		elseif x:find'%d+%s+thor' then
			--local d = x:gmatch('%d+[:%d*]*[%.%d*]*')
			local d = x:gmatch('%S+')
			--print('data',x)
			local dd = {}
			for v in d do table.insert(dd,v) end
			--util.ptable(dd)
			data[lut[dd[header['PID']]]] = {
				pid = dd[header['PID']],
				cpu = dd[header['%CPU']],
				mem = dd[header['%MEM']],
			}
		elseif x:find'PID' then
			--print('header',x)
			if not header then
				header = {}
				local h = x:gmatch('%S+')
				local idx = 1
				for v in h do
					header[v] = idx
					idx = idx+1
				end
			end -- no header
		end -- check type of reow
	end -- inf while
	fl:write(mp.pack(data))
	fl:close()

end

local function unlog()
	local fl = io.open(fname,'r')
	local file_str = fl:read('*a')
	local unpacker = msgpack.unpacker(file_str)
	local tbl = true
	while tbl do
		tbl = unpacker:unpack()
		if not tbl then break end
		-- Format
		if type(tbl)=='table' then
			util.ptable(tbl)
		else print(tbl) end
	end

end
if do_log then log() else unlog() end
