-- This module adds commands for controlling a WS2812-based LED strip.
local obj = {}

local math = {}

math.pi = 3141593 / 1000000

math.abs = function(v)
  return v < 0 and v * -1 or v
end

math.fmod = function(x, y)
  return x % y
end

math.correct_radians = function(v)
  while v > math.pi * 2 do
    v = v - math.pi * 2
  end

  while v < - math.pi * 2 do
    v = v + math.pi * 2
  end

  return v
end

math.pow = function(b, p)
  local e = b

  if (p == 0) then
    return 1
  end

  if (p < 0) then
    p = p * (-1)
  end

  for c = p, 2, -1 do
    e = e * b
  end

  return e
end

math.fact = function(b)
  if (b == 1) or (b == 0) then
    return 1
  end

  local e = 1

  for c = b, 1, -1 do
    e = e * c
  end

  return e
end

math.cos = function(b, p)
  local e = 1
  b = math.correct_radians(b)
  p = p or 10

  for i = 1, p do
    e = e + (math.pow(-1, i) * math.pow(b, 2 * i) / math.fact(2 * i))
  end

  return e
end

-- Ported from http://blog.saikoled.com/post/43693602826/why-every-led-light-should-be-using-hsi
local hsiToRgb = function (h, s, i)
  local r, g, b = 0

  h = math.fmod(h, 360) -- Cycle hue around to 0-360 degrees
  h = math.pi * h / 180 -- Convert to radians
  s = (s > 0) and ((s < 1) and s or 1) or 0 -- Clamp saturation to interval 0, 1
  i = (i > 0) and ((i < 1) and i or 1) or 0 -- Clamp intensity to interval 0, 1

  -- Math! Thanks in part to Kyle Miller.
  if h < 2.09439 then
    r = 255 * i / 3 * (1 + s * math.cos(h) / math.cos(1.047196667- h))
    g = 255 * i / 3 * (1 + s * (1 - math.cos(h) / math.cos(1.047196667- h)))
    b = 255 * i / 3 * (1 - s)
  elseif h < 4.188787 then
    h = h - 2.09439
    g = 255 * i / 3 * (1 + s * math.cos(h) / math.cos(1.047196667- h))
    b = 255 * i / 3 * (1 + s * (1 - math.cos(h) / math.cos(1.047196667- h)))
    r = 255 * i / 3 * (1 - s)
  else
    h = h - 4.188787
    b = 255 * i / 3 * (1 + s * math.cos(h) / math.cos(1.047196667- h))
    r = 255 * i / 3 * (1 + s * (1 - math.cos(h) / math.cos(1.047196667- h)))
    g = 255 * i / 3 * (1 - s)
  end

  return {r, g, b}
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
  local rgb = nil

  for i, v in pairs(sess.ws2812_buffer) do
    rgb = hsiToRgb(v[1], v[2], v[3])
    frame = frame .. string.char(rgb[1], rgb[2], rgb[3])
  end

  ws2812.writergb(cfg.data.ws2812_pin, frame)

  frame = nil
  rgb = nil
  collectgarbage()
end

obj._configuration_fields = function()
  return {
    ws2812_pin = {
      type = 'number',
      default = false
    },
    ws2812_leds = {
      type = 'number',
      default = 24,
      min = 1,
      max = 256
    }
  }
end

obj._command_handlers = function()
  if not cfg.data.ws2812_pin then
    return
  end

  -- Initialize frame buffer
  sess.ws2812_buffer = {}
  if cfg.data.ws2812_pin then
    setLedColor({0, 0, 0.25}, cfg.data.ws2812_leds)
  end

  local handlers = {}

  handlers['ws2812/control'] = function (evt)
    local hsi = {
      sess.ws2812_buffer[1][1],
      sess.ws2812_buffer[1][2],
      sess.ws2812_buffer[1][3]
    }

    if evt.data.hue then
      hsi[1] = evt.data.hue
    end

    if evt.data.saturation then
      hsi[2] = evt.data.saturation
    end

    if evt.data.intensity then
      hsi[3] = evt.data.intensity
    end

    if evt.data.hsi then
      hsi = evt.data.hsi
    end

    if (not evt.data.type) or (evt.data.type == 'instant') then
      setLedColor(hsi, cfg.data.ws2812_leds)
    elseif evt.data.type == 'fade' then
      local old = sess.ws2812_buffer[1]

      -- Calculate amount of steps based on difference between old and new color data
      local diff = {
        math.abs((hsi[1] - old[1]) / 18),
        math.abs((hsi[2] - old[2]) / 0.05),
        math.abs((hsi[3] - old[3]) / 0.05)
      }

      local step_count = diff[1]
      step_count = step_count < diff[2] and diff[2] or step_count
      step_count = step_count < diff[3] and diff[3] or step_count
      local step_counter = 0

      local steps = {
        (hsi[1] - old[1]) / step_count,
        (hsi[2] - old[2]) / step_count,
        (hsi[3] - old[3]) / step_count
      }

      while step_counter < step_count do
        step_counter = step_counter + 1

        local new_hsi = {
          old[1] + (steps[1] * step_counter),
          old[2] + (steps[2] * step_counter),
          old[3] + (steps[3] * step_counter)
        }

        setLedColor(new_hsi, cfg.data.ws2812_leds)
        tmr.delay(10000)
      end

      old = nil
      diff = nil
      step_count = nil
      step_counter = nil
      steps = nil
      new_hsi = nil
    end

    hsi = nil
    collectgarbage()
  end

  return handlers
end

return function(fnc, args)
  if obj[fnc] then
    return obj[fnc](args)
  end
end
