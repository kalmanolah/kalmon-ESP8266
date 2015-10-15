local settings = {}
settings.data = {}
settings.file = "settings.json"

function settings.load()
  if file.open(settings.file, "r") then
    local json = require "cjson"
    local content = file.read()

    if content ~= nil and content ~= "null" then
      settings.data = json.decode(content)
    end

    file.close()
  end
end

function settings.save()
  local json = require "cjson"
  file.open(settings.file, "w+")
  local content = json.encode(settings.data)
  file.write(content)
  file.close()
end

settings.load()

return settings
