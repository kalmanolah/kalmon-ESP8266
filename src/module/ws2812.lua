-- This module adds commands for controlling a WS2812-based LED strip.
local obj = {}

-- Ported from http://blog.saikoled.com/post/43693602826/why-every-led-light-should-be-using-hsi
local hsiToRgb = function (h, s, i)
  local rgb = {0, 0, 0}

  h = math.fmod(h, 360) -- Cycle hue around to 0-360 degrees
  h = 3.14159 * h / 180 -- Convert to radians
  s = (s > 0) and ((s < 1) and s or 1) or 0 -- Clamp saturation to interval 0, 1
  i = (i > 0) and ((i < 1) and i or 1) or 0 -- Clamp intensity to interval 0, 1

  -- Math! Thanks in part to Kyle Miller.
  if h < 2.09439 then
    rgb[1] = 255 * i / 3 * (1 + s * math.cos(h) / math.cos(1.047196667 - h))
    rgb[2] = 255 * i / 3 * (1 + s * (1 - math.cos(h) / math.cos(1.047196667 - h)))
    rgb[3] = 255 * i / 3 * (1 - s)
  else if h < 4.188787 then
    h = h - 2.09439
    rgb[2] = 255 * i / 3 * (1 + s * math.cos(h) / math.cos(1.047196667 - h))
    rgb[3] = 255 * i / 3 * (1 + s * (1-math.cos(h) / math.cos(1.047196667 - h)))
    rgb[1] = 255 * i / 3 * (1 - s)
  else
    h = h - 4.188787
    rgb[3] = 255 * i / 3 * (1 + s * math.cos(h) / math.cos(1.047196667 - h))
    rgb[1] = 255 * i / 3 * (1 + s * (1 - math.cos(h) / math.cos(1.047196667 - h)))
    rgb[2] = 255 * i / 3 * (1 - s)
  end

  return rgb
end

local setLedColor = function (hsi, length, offset)
  if not cfg.data.ws2812_pin then
    return
  end

  length = length or 1
  offset = offset or 1

  for i = offset, offset + length - 1 do
    sess.ws2812_buffer[i] = hsi
  end

  local frame = ''

  for i, v in pairs(sess.ws2812_buffer) do
    frame = frame .. string.char(table.concat(hsiToRgb(v)))
  end

  ws2812.writergb(cfg.data.ws2812_pin, frame)

  frame = nil
  collectgarbage()
end

obj.init = function ()
  sess.ws2812_buffer = {}

  -- Initialize frame buffer
  if cfg.data.ws2812_pin then
    setLedColor({30, 0.25, 0.25}, 64)
  end
end

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

  handlers['/ws2812/control'] = function(evt)
    if (not evt.data.type) or (evt.data.type == 'instant') then
      setLedColor(evt.data.hsi, evt.data.count)
    else if evt.data.type == 'fade' then
      local old = sess.ws2812_buffer[1]

      local duration = evt.data.duration or 5000
      local step_duration = evt.data.step or 500
      local step_count = duration / step_duration
      local step_counter = 0

      local steps = {
        (evt.data.hsi[1] - old[1]) / step_count,
        (evt.data.hsi[2] - old[2]) / step_count,
        (evt.data.hsi[3] - old[3]) / step_count
      }

      tmr.alarm(5, step_duration, 1, function()
        step_counter = step_counter + 1

        local hsi = {
          old[1] + (steps[1] * step_counter),
          old[2] + (steps[2] * step_counter),
          old[3] + (steps[3] * step_counter)
        }

        setLedColor(hsi, evt.data.count)

        if step_counter == step_count then
          tmr.stop(5)
          old = nil
          duration = nil
          step_duration = nil
          step_count = nil
          step_counter = nil
          steps = nil
        end

        hsi = nil
        collectgarbage()
      end)
    end
  end

  return handlers
end

return function(fnc, args)
  if obj[fnc] then
    return obj[fnc](args)
  end
end
