-----------------------------------------------------------------
-- Combined Lidar manager for Team THOR
-- Reads and sends raw lidar data
-- As well as accumulate them as a map
-- and send to UDP/TCP
-- (c) Stephen McGill, Seung Joon Yi, 2013
---------------------------------
-- TODO: Critical section for include
-- Something there is non-reentrant
dofile'../include.lua'
-- Going to be threading this
local simple_ipc = require'simple_ipc'
-- Are we a child?
local IS_CHILD, pair_ch = false, nil
local CTX, metadata = ...
if CTX and type(metadata)=='table' then
	IS_CHILD=true
	simple_ipc.import_context( CTX )
	pair_ch = simple_ipc.new_pair(metadata.ch_name)
	print('CHILD CTX')
end
-- For all threads
local mp = require'msgpack.MessagePack'

-- The main thread's job is to give:
-- joint angles and network request
if not IS_CHILD then
	print('PARENT')
	-- TODO: Signal of ctrl-c should kill all threads...
	local signal = require'signal'
	local util = require'util'
	local poller, channels = nil, {}
	-- Spawn children
	for _,cam in ipairs(Config.camera) do
		print(util.color('Setting up','green'))
		util.ptable(cam)
		-- The thread will automagically start detached upon gc
		local ch, thread = simple_ipc.new_thread('camera_wizard.lua',cam.name,cam)
		-- Deal with any data from the camera
		ch.callback = function(s)
			local data, has_more = poller.lut[s]:receive()
			--print('child tread data!',data)
		end
		-- Add the channel for our poller to sample
		channels[cam.name] = ch
		-- Start detached
		thread:start(true,true)
	end
	-- TODO: Also poll on mesh requests, instead of using net_settings...
	-- This would be a Replier (then people ask for data, or set data)
	-- Instead of changing shared memory a lot...
	local replier = simple_ipc.new_replier'mesh'
	replier.callback = function(s)
		local data, has_more = poller.lut[s]:receive()
		-- Send message to a thread
		local cmd = mp.unpack(data)
	end
	table.insert(channels,replier)
	-- Ensure that we shutdown the threads properly
	signal.signal("SIGINT", os.exit)
	signal.signal("SIGTERM", os.exit)
	-- Just wait for requests from the children
	poller = simple_ipc.wait_on_channels(channels)
	poller:start()
	return
end

-- Libraries
local util   = require'util'
local udp    = require'udp'
local uvc    = require'uvc'
local jpeg   = require'jpeg'

-- Extract metadata information
local w = metadata.width
local h = metadata.height
local fps = metadata.fps
local fmt = metadata.format
metadata = nil
-- Extract Config information
local operator = Config.net.operator.wired
local udp_port = Config.net.camera[cam.name]
Config = nil
-- Open the camera
local dev = uvc.init(metadata.dev, width, height, fmt, 1, fps)
-- UDP Sending
local camera_udp_ch = udp.new_sender(operator, udp_port)
-- Metadata for the operator
local meta = {
	t = 0,
	c = 'jpeg',
	w = w,
	h = h,
	name = cam.name..'_camera',
}
-- JPEG Compressor
local c_yuyv = jpeg.compressor('yuyv')

while true do
	-- Grab and compress
	local img, sz, cnt, t = dev:get_image()
	local c_img = c_yuyv:compress( img, camera.meta.w,camera.meta.h)
	-- Update metadata
	meta.t = t
	meta.sz = #c_img
	-- Send
	local udp_ret, err = camera.udp:send( mp.pack(meta)..c_img )
	print('SENT UDP',udp_ret,cnt,t)
	if err then print(camera.meta.name,'udp error',err) end
--	print('img',img)
end
