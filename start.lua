cfg = dofile("settings.lc")
for k,v in pairs(cfg.data) do print(k .. ": " .. tostring(v)) end

-- Starting out in STATIONAP mode helps prevent some silly adc.readvdd33() issues down the line
wifi.setmode(wifi.STATIONAP)

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
