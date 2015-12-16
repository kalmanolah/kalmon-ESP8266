-- This module adds battery voltage to reports. Due to certain
-- hardware limitations, battery voltage is only measured at boot.
obj = {}

obj.init = function()
  obj.reading = adc.readvdd33()
end

obj.report_data = function()
  local reading_str = string.format("%d.%03d", math.floor(obj.reading / 1000), obj.reading - ((obj.reading / 1000) * 1000))

  return {
    { "/sensors/battery/voltage", reading_str }
  }
end

return obj
