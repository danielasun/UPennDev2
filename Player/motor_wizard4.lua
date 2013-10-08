-----------------------------------
-- Dynamixel Motor Communication --
-- Performs callbacks for        --
-- libDynamixel Servicing        --
-- (c) Stephen McGill, 2013      --
-----------------------------------
dofile'include.lua'

-- Libraries
local Body   = require'Body'
local signal = require'signal'
local vector = require'vector'
local util   = require'util'
local libDynamixel = require'libDynamixel'
-- Easy access to useful elements
local joint_to_motor = Body.servo.joint_to_motor
local motor_to_joint = Body.servo.motor_to_joint
local jointNames = Body.jointNames
local DEG_TO_RAD = Body.DEG_TO_RAD
local RAD_TO_DEG = Body.RAD_TO_DEG
require'jcm'

--------------------
-- Setup helpful variables
local nMotors = 0
local status_color = {
  ['suspended'] = 'green',
  ['dead'] = 'red',
}
-- Lookup table for id to chain
local motor_to_dynamixel = {}
local idx_to_dynamixel = {}
local idx_to_ids  = {}
local idx_to_vals = {}

--------------------
-- Initialize the dynamixels
local dynamixels = {}
local chains = {}
chains['Right Arm'] = {
  ttyname = '/dev/ttyUSB0',
  nx_ids  = {1,3,5,7,9,11,13},
  mx_ids  = { --[[31,33,35]] },
  active = true
}
chains['Left Arm'] = {
  ttyname = '/dev/ttyUSB1',
  nx_ids  = {2,4,6,8,10,12,14, --[[head]] 29,30 },
  mx_ids  = { --[[32,34,36,]]   --[[lidar]] 37},
  active = false
}
chains['Right Leg'] = {
  ttyname = '/dev/ttyUSB2',
  nx_ids  = {15,17,19,21,23,25, --[[waist pitch]]28},
  mx_ids  = {},
  active = false
}
chains['Left Leg'] = {
  ttyname = '/dev/ttyUSB3',
  nx_ids  = {16,18,20,22,24,26, --[[waist]]27},
  mx_ids  = {},
  active = false
}
if OPERATING_SYSTEM=='darwin' then
  chains['Right Arm'].ttyname = '/dev/cu.usbserial-FTT3ABW9A'
  chains['Left Arm'].ttyname  = '/dev/cu.usbserial-FTT3ABW9B'
  chains['Right Leg'].ttyname = '/dev/cu.usbserial-FTT3ABW9C'
  chains['Left Leg'].ttyname  = '/dev/cu.usbserial-FTT3ABW9D'
end

--------------------
-- Callback processing on data from a named register
-- TODO: eliminate jcm, and use Body calls
-- TODO: that might be bad for performance, though
local update_read = function(self,data,register)

  if type(data)~='table' then return end
  -- Update the shared memory
  for k,v in pairs(data) do
    -- k is the motor id
    -- v is the register value
    local ptr = jcm.sensorPtr[register]
    assert(ptr,'Register is not in jcm!'..tostring(register))
    -- Find the humanoid joint
    local idx = motor_to_joint[k]
    local tptr = jcm.treadPtr[register]
    -- Debug
    --[[
    print(string.format('%s: %s %s is %g',
    self.name,jointNames[idx],register,v))
    --]]
    
    -- Specific handling of register types
    if register=='position' then
      if type(v)==number then
        ptr[idx] = Body.make_joint_radian( idx, v )
        -- Update the timestamp
        tptr[idx] = self.t_read
      end
    elseif register=='load' then
      if v>=1024 then v = v - 1024 end
      local load_ratio = v/10.24
      ptr[idx] = load_ratio
      -- Update the timestamp
      tptr[idx] = self.t_read
    elseif register=='rfoot' then
      local offset = (k-23)*2
      local data = carray.short( string.char(unpack(v)) )
      if #data==4 and offset>=0 and offset<=4 then
        ptr[offset+1] = 3.3*data[1]/4096 -- volts
        ptr[offset+2] = 3.3*data[2]/4096 -- volts
        ptr[offset+3] = 3.3*data[3]/4096 -- volts
        ptr[offset+4] = 3.3*data[4]/4096 -- volts
        -- Update the timestamp
        tptr[1] = self.t_read
      end
    elseif register=='lfoot' then
      local offset = (k-24)*2
      local data = carray.short( string.char(unpack(v)) )
      if #data==4 and offset>=0 and offset<=4 then
        ptr[offset+1] = 3.3*data[1]/4096 -- volts
        ptr[offset+2] = 3.3*data[2]/4096 -- volts
        ptr[offset+3] = 3.3*data[3]/4096 -- volts
        ptr[offset+4] = 3.3*data[4]/4096 -- volts
        tptr[1] = self.t_read
      end
    else
      ptr[idx] = v
      -- Update the timestamp
      tptr[idx] = self.t_read
    end

  end -- loop through data

end -- read callback function

--------------------
-- Clean Shutdown function
function shutdown()
  print'Shutting down the Dynamixel chains...'
  
  for d_id,d in ipairs(dynamixels) do
    -- Torque off motors
    libDynamixel.set_mx_torque_enable( d.mx_on_bus, 0, d )
    libDynamixel.set_nx_torque_enable( d.nx_on_bus, 0, d )

    -- TODO: Save the torque enable states to SHM
    -- Close the fd
    d:close()
    -- Print helpful message
    print('Closed',d.name)
  end
  os.exit()
end
signal.signal("SIGINT", shutdown)
signal.signal("SIGTERM", shutdown)

--------------------
-- Update the commands to write to the robot
-- TODO: What if too many commands?
local update_commands = function(t)
  -- Loop through the registers
  for register,write_ptr in pairs(jcm.writePtr) do
    local val_ptr     = jcm.actuatorPtr[register]
    local set_func    = libDynamixel['set_nx_'..register]
    local mx_set_func = libDynamixel['set_mx_'..register]
    local t_ptr = jcm.twritePtr[register]
    -- go through each value
    for idx=1,#write_ptr do
      is_write = write_ptr[idx]
      if is_write>0 then
        -- Add the write instruction to the chain
        local d = idx_to_dynamixel[idx]
        --if d and #d.commands==0 then
        if d then
          write_ptr[idx]=0
          table.insert( idx_to_ids[idx], joint_to_motor[idx] )
          --print(register,idx,'setting',idx_to_vals[idx], val_ptr[idx])
          if register=='command_position' then
            -- Convert from radians to steps for set command_position
            table.insert( idx_to_vals[idx], Body.make_joint_step(idx,val_ptr[idx]) )
          else
            if register=='command_velocity' then
            end
            table.insert( idx_to_vals[idx], val_ptr[idx] )
          end
          -- Update the write time
          t_ptr[idx] = t
        end
      end
    end -- for each enable
    -- Make the request for this register on each chain
    for _,d in ipairs(dynamixels) do
      if #d.packet_ids>0 and set_func then
        --print('making packet!',#d.packet_ids)
        -- Make the NX request
        table.insert( d.commands, 
          set_func(d.packet_ids,d.packet_vals) )
        -- reset
        for i,_ in ipairs(d.packet_ids) do
          d.packet_ids[i]  = nil
          d.packet_vals[i] = nil
        end
      end -- if nx
      if #d.mx_packet_ids>0 and mx_set_func then
        -- Make the MX request
        table.insert( d.commands, 
          mx_set_func(d.mx_packet_ids,d.mx_packet_vals) )
        for i,_ in ipairs(d.mx_packet_ids) do
          d.mx_packet_ids[i]  = nil
          d.mx_packet_vals[i] = nil
        end
      end -- if mx
    end -- for making commands for the chains
  end -- for each register
end

-- Set commands for next sync read

local function normal_read(register,read_ptr)
  local get_func    = libDynamixel['get_nx_'..register]
  local mx_get_func = libDynamixel['get_mx_'..register]
  for idx=1,#read_ptr do
    local is_read = read_ptr[idx]
    -- Check if we are to read each of the values
    if is_read>0 then
      -- Add the read instruction to the chain
      local d = idx_to_dynamixel[idx]
      if d and #d.requests==0 then
        -- Kill the reading
        read_ptr[idx] = 0
        table.insert( idx_to_ids[idx], joint_to_motor[idx] )
      end
    end
  end -- for each enable
  
  -- Make the request for this register on each chain
  for _,d in ipairs(dynamixels) do
    if #d.requests==0 then
      local nids = #d.packet_ids
      if nids>0 then
        -- Make the request
        local req = {
          nids = nids,
          reg  = register,
          inst = get_func(d.packet_ids)
        }
        table.insert( d.requests, req )
        for i,_ in ipairs(d.packet_ids) do d.packet_ids[i] = nil end
      end
      local mx_nids = #d.mx_packet_ids
      if mx_nids>0 then
        -- Make the request
        local req = {
          nids = mx_nids,
          reg  = register,
          inst = mx_get_func(d.mx_packet_ids)
        }
        table.insert( d.requests, req )
        for i,_ in ipairs(d.mx_packet_ids) do d.mx_packet_ids[i]  = nil end
      end
    end -- if #req==0
  end -- for making commands for the chains
end

local ext_read = {
  lfoot = function()
    -- TODO: Assuming that left feet are all on the same chain
    local reqs = motor_to_dynamixel[24]
    if reqs then
      table.insert( reqs.requests, {
        nids = 2,
        reg  = 'lfoot',
        inst = libDynamixel.get_nx_data({24,26})
      })
    end
  end,
  rfoot = function()
    -- TODO: Assuming that left feet are all on the same chain
    local reqs = motor_to_dynamixel[23]
    if reqs then
      table.insert( reqs.requests, {
        nids = 2,
        reg  = 'rfoot',
        inst = libDynamixel.get_nx_data({23,25})
      })
    end
  end
}

-- Update the read every so often
local update_requests = function(t)
  -- Loop through the registers
  for register,read_ptr in pairs(jcm.readPtr) do
    if register:find'foot' then
      if read_ptr[1] == 1 then
        read_ptr[1] = 0
        local func = ext_read[register]
        if func then func() end
      end
    else
      normal_read(register,read_ptr)
    end
  end -- for each register
end --function

--------------------
-- Begin the main routine
local led_state = 0
local main = function()
  local main_cnt = 0
  local t0 = Body.get_time()
  
  -- Enter the coroutine
  while true do
    local t = Body.get_time()
    
    -- Set commands for next sync write
    update_commands(t)
    update_requests(t)

    for _,d in ipairs(dynamixels) do
      print('latency',d.name,1/d.t_diff_cmd)
    end

    
    -- Show debugging information and blink the LED
    main_cnt = main_cnt + 1
    local t_diff = t - t0
    if t_diff>1 then
      local debug_tbl = {}
      table.insert(debug_tbl, string.format(
        'Main loop: %7.2f Hz\n', main_cnt/t_diff))
      led_state = 1-led_state
      for _,d in ipairs(dynamixels) do
        --[[
        -- Blink the led
        local sync_led_cmd = 
          libDynamixel.set_mx_led( d.mx_on_bus, led_state )
        local sync_led_red_cmd = 
          libDynamixel.set_nx_led_red( d.nx_on_bus, 255*led_state )
        table.insert( d.commands, sync_led_cmd )
        table.insert( d.commands, sync_led_red_cmd )
        --]]

        -- Append debugging information
        table.insert(debug_tbl,string.format(
          '\tRead: %4.2f seconds ago\tWrite: %4.2f seconds ago',
          t-d.t_read,t-d.t_command))
        --[[
        table.insert(debug_tbl,string.format(
          '\n\t%d requests in the pipeline',#d.requests))
        table.insert(debug_tbl,string.format(
          '\n\t%d commands in the pipeline',#d.commands))
        --]]
      end
      --os.execute('clear')
      print( table.concat(debug_tbl,'\n') )
      t0 = t
      main_cnt = 0
    end
    
    -- Do not yield anything for now
    --coroutine.yield()
    return
    
  end
end

--------------------
-- Dynamixel chain setup
-- Identify the MX/NX motor types on the chain
-- TODO: Verify with Body that the ids have the right motor type
local function entry()

  --------------------
  -- Check the dynamixels
  for key,chain in pairs(chains) do
    if chain.active then
      print(chain.ttyname)
      local d = libDynamixel.new_bus(chain.ttyname)
      if d then
        d.callback = update_read
        d.mx_on_bus = {}
        d.nx_on_bus = {}
        for _,id in ipairs(chain.mx_ids) do table.insert(d.mx_on_bus,id) end
        for _,id in ipairs(chain.nx_ids) do table.insert(d.nx_on_bus,id) end
        d.nMotors = #d.mx_on_bus+#d.nx_on_bus
        d.name = key
        table.insert(dynamixels,d)
        chain.id = #dynamixels
      end
    end
  end

  Body.entry()
  
  jcm.set_actuator_torque_enable(jcm.get_actuator_torque_enable()*0)
  jcm.set_write_torque_enable(jcm.get_write_torque_enable()*0)

  for didx,dynamixel in ipairs(dynamixels) do
    -- Some temporay variables
    dynamixel.packet_ids  = {}
    dynamixel.packet_vals = {}
    dynamixel.mx_packet_ids  = {}
    dynamixel.mx_packet_vals = {}

    if dynamixel.nMotors==0 then
      -- Check which ids are on this chain
      local ids_on_bus = dynamixel:ping_probe()
      if #ids_on_bus==0 then
        print('No motors on '..dynamixel.name)
        break
      end
      for _,id in ipairs(ids_on_bus) do
        local model_reg = libDynamixel.get_nx_model_num(id,dynamixel)
        assert(model_reg,string.format('Bad model! %d',id) )
        local model_parser = libDynamixel.byte_to_number[ #model_reg.parameter ]
        local model_version = model_parser(unpack(model_reg.parameter))
        if model_version==29 then
          table.insert( dynamixel.mx_on_bus, model_reg.id )
        else
          table.insert( dynamixel.nx_on_bus, model_reg.id )
        end
      end
    end
    nMotors = nMotors + dynamixel.nMotors
    
    -- Read each motor id to classify each as NX or MX motors
    -- NOTE: NX and MX have same model register structure,
    -- so it is OK to use get_nx_ for both MX and NX
    -- TODO: There is a model difference on the right shoulder!
    --[[
    if not dynamixel.mx_on_bus or not dynamixel.nx_on_bus then
      io.write('Checking motor model numbers...')
      io.flush()
      for _,id in ipairs(dynamixel.ids_on_bus) do
        local model_reg = libDynamixel.get_nx_model_num(id,dynamixel)
        assert(model_reg,string.format('Bad model! %d',id) )
        local model_parser = libDynamixel.byte_to_number[ #model_reg.parameter ]
        local model_version = model_parser(unpack(model_reg.parameter))
        if model_version==29 then
          table.insert( dynamixel.mx_on_bus, model_reg.id )
        else
          table.insert( dynamixel.nx_on_bus, model_reg.id )
        end
      end
      io.write'Done!\n'
      io.flush()
    end
    --]]
    
    -- Debug the chain a bit
    local mx_table = {}
    for _,id in ipairs(dynamixel.mx_on_bus) do
      table.insert(mx_table,Body.jointNames[motor_to_joint[id]])
    end
    local nx_table = {}
    for _,id in ipairs(dynamixel.nx_on_bus) do
      table.insert(nx_table,Body.jointNames[motor_to_joint[id]])
    end
    print(util.color(dynamixel.name,'green'))
    print(util.color(#dynamixel.mx_on_bus..' MX:','magenta'),
      table.concat(mx_table,', '))
    print(util.color(#dynamixel.nx_on_bus..' NX:','magenta'),
      table.concat(nx_table,', '))
    
    -- TODO: Set the status return level on every startup?
    --local status = libDynamixel.set_nx_status_return_level(m,1,test_dynamixel)
    
    -- Perform a read to instantiate the motor commands and sensor positions
    local status
    for _,id in ipairs(dynamixel.nx_on_bus) do
      local idx = motor_to_joint[id]
      
      -- Torque off the motor
      status = libDynamixel.set_nx_torque_enable(id,0,dynamixel)
      assert(status, string.format('NX | %s: Did not torque off %s: %d',
        dynamixel.name,Body.jointNames[idx],id) )
      assert(status.error==0,
        string.format("Torque enable error! %d", status.error) )
      dynamixel.t_command = Body.get_time()

      -- Read the NX motor positions
      status = libDynamixel.get_nx_position(id,dynamixel)
      assert(status, string.format('NX | %s: No position for ID %s: %d',
        dynamixel.name,Body.jointNames[idx],id) )
      assert(status.error==0, 
        string.format("Get position error! %d", status.error) )
      dynamixel.t_read = Body.get_time()

      -- Parse the value
      local pos_parser = libDynamixel.byte_to_number[ #status.parameter ]
      local pos_val = pos_parser(unpack(status.parameter))
      local rad = Body.make_joint_radian( idx, pos_val )

      -- Sync shared memory
      jcm.sensorPtr.position[idx] = rad
      jcm.actuatorPtr.command_position[idx] = rad

      -- Populate the lookup table from id to chain
      idx_to_dynamixel[idx]  = dynamixel
      motor_to_dynamixel[id] = dynamixel
      idx_to_ids[idx]  = dynamixel.packet_ids
      idx_to_vals[idx] = dynamixel.packet_vals
      
      -- Debug output
      --[[
      print( util.color(Body.jointNames[idx],'yellow'), '\n',
        string.format('\t%d (%d) @ %.2f, step: %d',
        idx,id,rad*Body.RAD_TO_DEG,pos_val) )
      --]]

    end -- NX position sync
    
    -- Perform a read to instantiate the motor commands and sensor positions
    for _,id in ipairs(dynamixel.mx_on_bus) do
      local idx = motor_to_joint[id]
      
      -- Torque off the motor
      status = libDynamixel.set_mx_torque_enable(id,0,dynamixel)
      assert(status, string.format('MX | %s: Did not torque off %s: %d',
        dynamixel.name,Body.jointNames[idx],id) )
      assert(status.error==0,
        string.format("Torque enable error! %d", status.error) )
      dynamixel.t_command = Body.get_time()
      
      -- Read the motor position
      status = libDynamixel.get_mx_position(id,dynamixel)
      assert(status, string.format('MX | %s: No position for ID %s: %d',
        dynamixel.name,Body.jointNames[idx],id) )
      assert(status.error==0, 
        string.format("Get position error! %d", status.error) )
      dynamixel.t_read = Body.get_time()

      -- Parse the value
      local pos_parser = libDynamixel.byte_to_number[ #status.parameter ]
      local pos_val = pos_parser(unpack(status.parameter))
      local rad = Body.make_joint_radian( idx, pos_val )

      -- Sync shared memory
      jcm.sensorPtr.position[idx] = rad
      jcm.actuatorPtr.command_position[idx] = rad

      -- Populate the tables
      idx_to_dynamixel[idx]  = dynamixel
      motor_to_dynamixel[id] = dynamixel
      idx_to_ids[idx]  = dynamixel.mx_packet_ids
      idx_to_vals[idx] = dynamixel.mx_packet_vals
      
      -- Debug output
      --[[
      print( util.color(Body.jointNames[idx],'yellow'), '\n',
        string.format('\t%d (%d) @ %.2f, step: %d',
        idx,id,rad*Body.RAD_TO_DEG,pos_val) )
      --]]
    end -- MX position sync
  end -- for each dynamixel chain
end -- entry

--------------------
-- Start the service loop
entry()
print()
assert(#dynamixels>0,"No dynamixel buses!")
assert(nMotors>0,"No dynamixel motors found!")
print( string.format('Servicing %d dynamixel chains',#dynamixels) )
--libDynamixel.service( dynamixels, main )
libDynamixel.straight_service(dynamixels[1], main)