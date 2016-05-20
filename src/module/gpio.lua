-- This module adds commands for controlling IOs.
_k.cmd('gpio/control', function (e)
  local pin = e.pin
  local state = e.state == true and gpio.HIGH or gpio.LOW
  gpio.mode(pin, gpio.OUTPUT)

  if (not e.type) or (e.type == 'set') then
    gpio.write(pin, state)
  elseif e.type == 'pulse' then
    gpio.write(pin, state)
    tmr.delay(e.duration and (e.duration * 1000) or 500000)
    gpio.write(pin, state == gpio.HIGH and gpio.LOW or gpio.HIGH)
  end
end)
