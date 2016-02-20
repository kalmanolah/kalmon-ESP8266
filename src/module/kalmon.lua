-- This module adds some core functionality.
-- See https://github.com/kalmanolah/kalmon-ESP8266
-- See https://github.com/kalmanolah/kalmon-web
local obj = {}

obj._report_data = function()
  return {
    { "/heartbeat", "ping" }
  }
end

obj._command_handlers = function()
  local handlers = {}

  handlers['/ping'] = function(evt)
    return {
      rid = evt.data.rid or nil,
      node = mq_id,
    }
  end

  handlers['info'] = function(evt)
    local files = {}
    for f, s in pairs(file.list()) do
      files[#files + 1] = {f, s}
    end

    return {
      node = node.info(),
      files = files,
      cfg = cfg.data,
    }
  end

  handlers['restart'] = function(evt)
    node.restart()
  end

  handlers['cfg/set'] = function(evt)
    cfg.data[evt.data.key] = evt.data.value
    triggerModule('settings', 'save')
  end

  handlers['files/remove'] = function(evt)
    file.remove(evt.data.file)
  end

  handlers['files/create'] = function(evt)
    file.open(evt.data.file, "w+")
    file.write(evt.data.content)
    file.close()
  end

  return handlers
end

return function(fnc, args)
  if obj[fnc] then
    return obj[fnc](args)
  end
end