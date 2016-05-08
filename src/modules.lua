-- Load all modules
loadModules = function()
  local name = nil
  modules = {}

  for i, f in ipairs(getMatchedFiles('^module/.+%.lc')) do
    name = f:gsub('^module/', ''):gsub('%.lc', '')
    modules[name] = f
  end

  name = nil
  collectgarbage()
end

-- Trigger a specific method on a module
triggerModule = function(mdl, ev)
  local result = nil

  result = dofile(modules[mdl])(ev)
  collectgarbage()

  return result
end

-- Trigger a specific method on all modules
triggerModules = function(ev)
  local results = {}
  local temp_result = nil

  for n, m in pairs(modules) do
    temp_result = triggerModule(n, ev)

    if temp_result ~= nil then
      results[#results + 1] = temp_result
    end
  end

  temp_result = nil
  collectgarbage()

  return results
end

-- Create module from table
makeModule = function(obj)
  return function(func, args)
    return obj[func] and obj[func](args)
  end
end

loadModules()
loadModules = nil
triggerModules('_init')
collectgarbage()
