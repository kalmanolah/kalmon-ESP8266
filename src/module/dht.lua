-- This module adds reporting temperature and humidity readings
-- from a DHT temp/hum sensor to reports.
local obj = {}

obj._configuration_fields = function()
  return {
    dht_pin = {
      type = 'number',
      default = false
    }
  }
end

obj._report_data = function()
  if not cfg.data.dht_pin then
    return
  end

  local dht_pin = cfg.data.dht_pin
  gpio.mode(dht_pin, gpio.INPUT)
  local status, temp, hum, temp_dec, hum_dec = dht.read(dht_pin)

  if status == dht.OK then
    return {
      { "/sensors/temperature", string.format("%d.%03d", math.floor(temp), temp_dec) },
      { "/sensors/humidity", string.format("%d.%03d", math.floor(hum), hum_dec) }
    }
  else
    if status == dht.ERROR_CHECKSUM then
      print("DHT Checksum error.")
    elseif status == dht.ERROR_TIMEOUT then
      print("DHT Timeout.")
    end

    return nil
  end
end

return function(fnc, args)
  if obj[fnc] then
    return obj[fnc](args)
  end
end
