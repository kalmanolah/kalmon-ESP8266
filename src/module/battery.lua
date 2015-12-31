-- This module adds battery voltage to reports. Due to certain
-- hardware limitations, battery voltage is only measured at boot.
local obj = {}

obj._init = function()
  obj.reading = adc.readvdd33()
end

obj._report_data = function()
  if not obj.reading then
    return
  end

  local reading_str = string.format("%d.%03d", math.floor(obj.reading / 1000), obj.reading - ((obj.reading / 1000) * 1000))

  return {
    { "/sensors/battery/voltage", reading_str }
  }
end

return function(fnc, args)
  if obj[fnc] then
    return obj[fnc](args)
  end
end
