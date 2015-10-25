local compileAndRemoveIfNeeded = function(f)
  if file.open(f) then
    file.close()
    print('Compiling:', f)
    node.compile(f)
    file.remove(f)
    collectgarbage()
  end
end

local compileFiles = {
  'httpserver-static.lua',
  'httpserver-basicauth.lua',
  'httpserver-conf.lua',
  'httpserver-error.lua',
  'httpserver-b64decode.lua',
  'httpserver-header.lua',
  'httpserver-request.lua',
  'httpserver.lua',
  'http/web_settings.lua',
  'settings.lua',
  'configure.lua',
  'application.lua',
  'start.lua'
}
for i, f in ipairs(compileFiles) do compileAndRemoveIfNeeded(f) end
compileAndRemoveIfNeeded = nil
compileFiles = nil
collectgarbage()

dofile("start.lc")
