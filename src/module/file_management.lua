-- This module adds file CRUD functionality, allowing for easier
-- implementation of OTA updates.
local obj = {}

obj.command_handlers = function()
  return {
    '/files/read' = function(data)
      local content = nil

      if file.open(data.target, 'r') then
        content = file.read()
        file.close()
      end

      return content
    end,

    '/files/rename' = function(data)
      file.rename(data.source, data.destination)
    end,

    '/files/remove' = function(data)
      file.remove(data.target)
    end,

    '/files/create' = function(data)
      file.open(data.target, "w+")
      file.write(data.content)
      file.close()
    end
  }
end

return obj
