-- This module adds commands for controlling a WS2812-based LED strip.
local obj = {}

obj.configuration_fields = function()
  return {
    ws2812_pin = {
      type = 'number',
      default = false
    }
  }
end

obj.command_handlers = function()
  if not cfg.data.ws2812_pin then
    return
  end

  local handlers = {}

  handlers['/ws2812/color'] = function(data)
    local rgb = cjson.decode(data)
    rgb = string.char(rgb.r, rgb.g, rgb.b)
    ws2812.writergb(cfg.data.ws2812_pin, rgb)

    rgb = nil
    collectgarbage()
  end

  return handlers
end

return function(fnc, args)
  if obj[fnc] then
    return obj[fnc](args)
  end
end
