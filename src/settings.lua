local settings = {}

settings.data = {}
settings.file = "settings.json"

settings.fields = {
  sta_ssid = {},
  sta_psk = {},

  ap_psk = {
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
    default = 'user'
  },
  mqtt_password = {
    default = 'password'
  },
  mqtt_host = {
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

-- Load cfg fields from modules
local configuration_fields = triggerModules('configuration_fields')
configuration_fields = tablesMerge(configuration_fields)
tableMerge(settings.fields, configuration_fields)
configuration_fields = nil
collectgarbage()

function settings.load()
  if file.open(settings.file, "r") then
    local json = require "cjson"
    local content = file.read()

    if content ~= nil and content ~= "null" then
      settings.data = json.decode(content)
    end

    file.close()
  end

  -- Populate empty fields with default data
  for k, v in ipairs(settings.fields) do
    if not not settings.data[k] then
      settings.data[k] = v.default
    end
  end

  collectgarbage()
end

function settings.save()
  local json = require "cjson"
  file.open(settings.file, "w+")
  local content = json.encode(settings.data)
  file.write(content)
  file.close()

  collectgarbage()
end

settings.load()

return settings
