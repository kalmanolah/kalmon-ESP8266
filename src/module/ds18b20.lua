-- Grabs DS18B20 readings, ow/bit modules required
-- Code based on DS18B20 module (MIT) by Vladimir Dronnikov
-- https://raw.githubusercontent.com/nodemcu/nodemcu-firmware/master/lua_examples/yet-another-ds18b20.lua
ds18b20 = {
  read = function(p)
    local r = nil
    local d = nil

    ow.setup(p)
    ow.reset_search(p)
    ow.target_search(p, 0x28)
    d = ow.search(p)
    if d == nil then return end

    ow.reset(p)
    ow.skip(p)
    ow.write(p, 0x44, 1)

    tmr.delay(750000)
    ow.reset(p)
    ow.select(p, d)
    ow.write(p, 0xBE, 1)

    local x = ow.read_bytes(p, 9)
    if ow.crc8(x) == 0 then
      local t = (x:byte(1) + x:byte(2) * 256)
      -- negatives?
      if bit.isset(t, 15) then t = 1 - bit.bxor(t, 0xffff) end
      -- NB: temperature in Celsius * 10^4
      t = t * 625
      if t ~= 850000 then
        r = t
      end
    end

    return r
  end
}

_k.on('_cfg.fields', function ()
  return {
    ds18b20_pin = {
      type = 'number',
      default = false
    }
  }
end)

_k.on('_report', function ()
  if not cfg.data.ds18b20_pin then
    return
  end

  local r = ds18b20.read(cfg.data.ds18b20_pin)
  if r ~= nil then
    return {{ "/sensors/ds18b20/temperature", string.format("%d.%04d", math.floor(r / 10000), r - ((r / 10000) * 10000)) }}
  end
end)
