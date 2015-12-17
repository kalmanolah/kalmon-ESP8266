-- Attempts to compile and remove a file if it exists
compileAndRemoveFile = function(f)
  if file.open(f) then
    file.close()

    print('Compiling:', f)
    node.compile(f)

    print('Removing:', f)
    file.remove(f)

    collectgarbage()
  end
end

-- Return an array containing file names matching a string
getMatchedFiles = function(s)
  local r = {}

  for k, v in pairs(file.list()) do
    if string.find(k, s, 1) ~= nil then
      r[#r + 1] = k
    end
  end

  collectgarbage()

  return r
end

-- Compile and remove all lua except for init.lua
compileAndRemoveLuaFiles = function()
  for i, f in ipairs(getMatchedFiles('%.lua$')) do
    if f ~= 'init.lua' then
      compileAndRemoveFile(f)
    end
  end

  collectgarbage()
end

-- Load all modules
loadModules = function()
  modules = {}

  for i, f in ipairs(getMatchedFiles('^module/.+%.lc')) do
    modules[#modules + 1] = dofile(f)
  end

  collectgarbage()
end

-- Trigger a specific method on all modules, if implemented
triggerModules = function(ev)
  local results = {}
  local temp_result = nil

  for i, m in ipairs(modules) do
    if m[ev] ~= nil then
      temp_result = m[ev]()

      if temp_result ~= nil then
        results[#results + 1] = temp_result
      end
    end
  end

  temp_result = nil
  collectgarbage()

  return results
end

-- Merges a second table into the first one
tableMerge = function(tbl1, tbl2)
  for k, v in pairs(tbl2) do
    if type(k) == 'number' then
      tbl1[#tbl1 + 1] = v
    else
      tbl1[k] = v
    end
  end
end

-- Merges an array of tables into a single table
tablesMerge = function(tbls)
  local results = {}

  for _, v in pairs(tbls) do
    tableMerge(results, v)
  end

  return results
end

compileAndRemoveLuaFiles()
loadModules()

cfg = dofile('settings.lc')
for k, v in pairs(cfg.data) do print(k .. ": " .. tostring(v)) end

triggerModules('init')

gpio.mode(cfg.data.cfg_pin, gpio.INPUT)
local tries = 0
local maxTries = 3
tmr.alarm(0, 1000, 1, function()
  print('Mode: Determining..')
  local cfg_pin = gpio.read(cfg.data.cfg_pin)
  tries = tries + 1

  if cfg_pin == gpio.LOW or tries == maxTries then
    local tries = nil
    local maxTries = nil
    tmr.stop(0)
    collectgarbage()

    if cfg_pin == gpio.LOW then
      print('Mode: Configure')
      dofile('configure.lc')
    else
      print('Mode: Application')
      dofile('application.lc')
    end
  end
end)