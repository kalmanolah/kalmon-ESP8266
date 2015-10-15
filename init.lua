local compileAndRemoveIfNeeded = function(f)
  if file.open(f) then
    file.close()
    print('Compiling:', f)
    node.compile(f)
    file.remove(f)
    collectgarbage()
  end
end

local compileFiles = {
  'httpserver-static.lua',
  'httpserver-basicauth.lua',
  'httpserver-conf.lua',
  'httpserver-error.lua',
  'httpserver-b64decode.lua',
  'httpserver-header.lua',
  'httpserver-request.lua',
  'httpserver.lua',
  'http/web_settings.lua',
  'settings.lua',
  'configure.lua',
  'application.lua'
}
for i, f in ipairs(compileFiles) do compileAndRemoveIfNeeded(f) end
compileAndRemoveIfNeeded = nil
compileFiles = nil
collectgarbage()

cfg = dofile("settings.lc")
for k,v in pairs(cfg.data) do print(k .. ": " .. v) end

gpio.mode(cfg.data.cfg_pin, gpio.INPUT)
local tries = 0
local maxTries = 3
tmr.alarm(0, 1000, 1, function()
  print('Mode: Determining..')
  local cfg_pin = gpio.read(cfg.data.cfg_pin)
  tries = tries + 1

  if cfg_pin == gpio.LOW or tries == maxTries then
    local tries = nil
    local maxTries = nil
    tmr.stop(0)
    collectgarbage()

    if cfg_pin == gpio.LOW then
      print('Mode: Configure')
      dofile('configure.lc')
    else
      print('Mode: Application')
      dofile('application.lc')
    end
  end
end)
