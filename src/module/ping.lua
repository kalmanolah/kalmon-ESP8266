-- This module sends a heartbeat on every report.
local obj = {}

obj._report_data = function()
  return {
    { "/heartbeat", "ping" }
  }
end

return function(fnc, args)
  if obj[fnc] then
    return obj[fnc](args)
  end
end
