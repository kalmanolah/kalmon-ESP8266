-- This module adds reporting temperature and humidity readings from a DHT temp/hum sensor to reports.
_k.on('_cfg.fields', function ()
  return {
    dht_pin = {
      type = 'number',
      default = false
    }
  }
end)

_k.on('_report', function ()
  if not cfg.data.dht_pin then
    return
  end

  local dht_pin = cfg.data.dht_pin
  gpio.mode(dht_pin, gpio.INPUT)
  local status, temp, hum, temp_dec, hum_dec = dht.read(dht_pin)

  if status == dht.OK then
    return {
      { "/sensors/dht/temperature", string.format("%d.%03d", math.floor(temp), temp_dec) },
      { "/sensors/dht/humidity", string.format("%d.%03d", math.floor(hum), hum_dec) }
    }
  else
    if status == dht.ERROR_CHECKSUM then
      print("DHT Checksum error.")
    elseif status == dht.ERROR_TIMEOUT then
      print("DHT Timeout.")
    end
  end
end)
