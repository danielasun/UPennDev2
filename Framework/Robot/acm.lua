require('Config')
require('carray')
require('vector')
require('util')
require('shm')

---------------------------------------------------------------------------
-- acm : actuator communications manager
---------------------------------------------------------------------------

acm = {}

-- configure device data and write access
---------------------------------------------------------------------------

local devices = {
  joint = {
    'joint_enable',
    'joint_force',
    'joint_position',
    'joint_velocity',
    'joint_stiffness',
    'joint_damping',
  }
}

local key_device = {}
acm.device_id = {}
acm.device_index = {}
acm.device_write_access = {}

for device in pairs(devices) do
  for _,key in pairs(devices[device]) do
    key_device[key] = device
  end
end

for device in pairs(devices) do
  acm.device_id[device] = Config[device] and Config[device].id
  acm.device_index[device] = Config[device] and Config[device].index
  acm.device_write_access[device] = vector.ones(#acm.device_id[device])
end

-- configure shared memory
---------------------------------------------------------------------------

-- define shared data fields and update flags 
local shared_data = {}
for key,device in pairs(key_device) do
  shared_data[key] = vector.zeros(#acm.device_id[device])
  shared_data[key..'_updated'] = vector.zeros(#acm.device_id[device])
end

-- initialize shared memory segment
acm.shm = shm.new('actuator')
util.init_shm_keys(acm.shm, shared_data)

-- get array access to shared data 
local data = {}
for key in pairs(shared_data) do
  data[key] = carray.cast(acm.shm:pointer(key))
end

-- define access methods
---------------------------------------------------------------------------

local function get_settings_table(value, index)
  index = index or 1
  local t = {}
  if (type(index) == 'number') then
    if (type(value) == 'table') then
      for i = 1,#value do
        t[index+i-1] = value[i]
      end
    elseif (type(value) == 'number') then
      t[index] = value
    end
  elseif (type(index) == 'table') then
    if (type(value) == 'table') then
      for i = 1,#index do
        t[index[i]] = value[i]
      end
    elseif (type(value) == 'number') then
      for i = 1,#index do
        t[index[i]] = value
      end
    end
  end
  return t
end

function acm:set_key(key, value, index)
  local device = key_device[key]
  if (not device) then
    return false
  end
  local device_index = self.device_index[device]
  local device_write_access = self.device_write_access[device]
  if (type(index) == 'string') then
    index = device_index[index]
  end
  local key_updated = key..'_updated'
  local settings = get_settings_table(value, index)
  for i,v in pairs(settings) do
    if (device_write_access[i] == 1) then
      data[key][i] = v
      data[key_updated][i] = 1
    end
  end
  return true
end

function acm:get_key(key, index)
  local device = key_device[key]
  if (not device) then
    return nil
  end
  local device_index = self.device_index[device]
  if (type(index) == 'string') then
    index = device_index[index]
  end
  if (type(index) == 'number') then
    return data[key][index]
  elseif (type(index) == 'table') then
    local t = vector.new()
    for i = 1,#index do
      t[i] = data[key][index[i]]
    end
    return t
  elseif (type(index) == 'nil') then
    local t = vector.new()
    for i = 1,#data[key] do
      t[i] = data[key][i]
    end
    return t
  end
end

function acm:set_write_access(key, value, index)
  local device = devices[key] and key or key_device[key]
  if (not device) then
    return false
  end
  local device_index = self.device_index[device]
  local device_write_access = self.device_write_access[device]
  if (type(index) == 'string') then
    index = device_index[index]
  end
  local settings = get_settings_table(value, index)
  for i,v in pairs(settings) do
    device_write_access[i] = v
  end
  return true
end

function acm:get_write_access(key, value, index)
  local device = devices[key] and key or key_device[key]
  if (not device) then
    return nil
  end
  local device_index = self.device_index[device]
  local device_write_access = self.device_write_access[device]
  if (type(index) == 'string') then
    index = device_index[index]
  end

  if (type(index) == 'number') then
    return device_write_access[index]
  elseif (type(index) == 'table') then
    local t = vector.new()
    for i = 1,#index do
      t[i] = device_write_access[index[i]]
    end
    return t
  elseif (type(index) == 'nil') then
    local t = vector.new()
    for i = 1,#device_write_access do
      t[i] = device_write_access[i]
    end
    return t
  end
end

function acm:get_device(key)
  return key_device[key]
end

for key,device in pairs(key_device) do
  acm['set_'..key] =
    function (self, value, index)
      return self:set_key(key, value, index)
    end
  acm["get_"..key] =
    function (self, index)
      return self:get_key(key, index)
    end
  acm['set_'..key..'_write_access'] =
    function (self, value, index)
      return self:set_write_access(device, value, index)
    end
  acm['get_'..key..'_write_access'] =
    function (self, index)
      return self:get_write_access(device, index)
    end
  acm['get_'..key..'_device'] = 
    function (self, index)
      return device
    end
end

for device in pairs(devices) do
  acm['set_'..device..'_write_access'] =
    function (self, value, index)
      return self:set_write_access(device, value, index)
    end
  acm['get_'..device..'_write_access'] =
    function (self, index)
      return self:get_write_access(device, index)
    end
end

-- define constructor for instances with private write access
---------------------------------------------------------------------------

function acm.new_access_point()
  local o = {}
  o.device_write_access = {}
  for k,v in pairs(acm.device_write_access) do
    o.device_write_access[k] = vector.ones(#v) -- access enabled by default
  end
  return setmetatable(o, {__index = acm})
end

return acm
