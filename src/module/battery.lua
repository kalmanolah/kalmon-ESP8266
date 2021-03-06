-- Module adding battery voltage to reports.
_k.on('_init', function ()
  if adc.force_init_mode(adc.INIT_VDD33) then
    node.restart()
  end
end)

_k.on('_report', function ()
  local r = adc.readvdd33()

  return {
    { "/sensors/battery/voltage", string.format("%d.%03d", math.floor(r / 1000), r - ((r / 1000) * 1000)) }
  }
end)
