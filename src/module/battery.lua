-- Module adding battery voltage to reports.
local obj = {}

obj._report_data = function()
  local r = adc.readvdd33()

  return {
    { "/sensors/battery/voltage", string.format("%d.%03d", math.floor(r / 1000), r - ((r / 1000) * 1000)) }
  }
end

return makeModule(obj)
