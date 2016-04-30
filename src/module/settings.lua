-- This module adds a settings API.
local obj = {}

obj._init = function()
  -- Define global cfg object
  cfg = {}
  cfg.data = {}
  cfg.file = 'settings.json'
  obj.load()
end

obj._configuration_fields = function()
  return {
    sta_ssid = {
      type = 'text',
      default = false
    },
    sta_psk = {
      type = 'text',
      default = false
    },
    sta_ip = {
      type = 'text',
      default = false
    },
    sta_netmask = {
      type = 'text',
      default = false
    },
    sta_gateway = {
      type = 'text',
      default = false
    },

    ap_psk = {
      type = 'text',
      default = 'ESP-8266'
    },
    ws_port = {
      type = 'number',
      min = '1',
      max = '65535',
      default = 80
    },
    cfg_pin = {
      type = 'number',
      default = 4
    },

    mqtt_user = {
      type = 'text',
      default = 'user'
    },
    mqtt_password = {
      type = 'text',
      default = 'password'
    },
    mqtt_host = {
      type = 'text',
      default = 'mqtt.local'
    },
    mqtt_port = {
      type = 'number',
      min = '1',
      max = '65535',
      default = 1337
    },
    mqtt_secure = {
      type = 'boolean',
      default = false
    },

    sleep = {
      type = 'boolean',
      default = false
    },
    report_interval = {
      type = 'number',
      min = '30',
      max = '604800',
      default = 60
    }
  }
end

-- Load cfg fields from modules
obj.fields = function()
  local gathered = triggerModules('_configuration_fields')
  local merged = tablesMerge(gathered)

  gathered = nil
  collectgarbage()

  return merged
end

-- Load cfg
obj.load = function()
  if file.open(cfg.file, "r") then
    local content = file.read()

    if content ~= nil and content ~= "null" then
      cfg.data = cjson.decode(content)
    end

    file.close()
  end

  -- Populate empty fields with default data
  local fields = obj.fields()

  for k, v in pairs(fields) do
    if cfg.data[k] == nil then
      cfg.data[k] = v.default
    end
  end

  fields = nil
  content = nil

  collectgarbage()
end

obj.save = function()
  file.open(cfg.file, "w+")
  local content = cjson.encode(cfg.data)
  file.write(content)
  file.close()
  content = nil

  collectgarbage()
end

return function(fnc, args)
  if obj[fnc] then
    return obj[fnc](args)
  end
end
