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

  handlers['/info'] = function(evt)
    return cjson.encode({
      node = node.info(),
      files = file.list(),
      cfg = cfg.data,
    })
  end

  -- handlers['/files/read'] = function(evt)
  --   local content = nil

  --   if file.open(evt.data.target, 'r') then
  --     content = file.read()
  --     file.close()
  --   end

  --   return content
  -- end

  -- handlers['/files/rename'] = function(evt)
  --   file.rename(evt.data.source, evt.data.target)
  -- end

  -- handlers['/files/remove'] = function(evt)
  --   file.remove(evt.data.target)
  -- end

  -- handlers['/files/create'] = function(evt)
  --   file.open(evt.data.target, "w+")
  --   file.write(evt.data.content)
  --   file.close()
  -- end

  return handlers
end

return function(fnc, args)
  if obj[fnc] then
    return obj[fnc](args)
  end
end
