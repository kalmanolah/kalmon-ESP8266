-- This module adds file CRUD functionality, allowing for easier
-- implementation of OTA updates.
local obj = {}

obj.command_handlers = function()
  local handlers = {}

  handlers['/files/read'] = function(data)
    local content = nil

    if file.open(data.target, 'r') then
      content = file.read()
      file.close()
    end

    return content
  end

  handlers['/files/rename'] = function(data)
    file.rename(data.source, data.destination)
  end

  handlers['/files/remove'] = function(data)
    file.remove(data.target)
  end

  handlers['/files/create'] = function(data)
    file.open(data.target, "w+")
    file.write(data.content)
    file.close()
  end

  return handlers
end

return function(fnc, args)
  if obj[fnc] then
    return obj[fnc](args)
  end
end
