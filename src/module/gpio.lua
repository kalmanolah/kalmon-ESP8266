-- This module adds commands for controlling IOs.
local obj = {}

obj._command_handlers = function()
  local handlers = {}

  handlers['gpio/control'] = function (evt)
    local pin = evt.data.pin
    local state = evt.data.state == true and gpio.HIGH or gpio.LOW

    gpio.mode(pin, gpio.OUTPUT)

    if (not evt.data.type) or (evt.data.type == 'set') then
      gpio.write(pin, state)
    elseif evt.data.type == 'pulse' then
      gpio.write(pin, state)
      tmr.delay(evt.data.duration and (evt.data.duration * 1000) or 500000)
      gpio.write(pin, state == gpio.HIGH and gpio.LOW or gpio.HIGH)
    end

    pin = nil
    state = nil
    collectgarbage()
  end

  return handlers
end

return makeModule(obj)
