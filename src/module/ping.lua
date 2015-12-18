-- This module sends a heartbear on every report.
local obj = {}

obj.report_data = function()
  return {
    { "/heartbeat", "ping" }
  }
end

return function(fnc, args)
  if obj[fnc] then
    return obj[fnc](args)
  end
end
