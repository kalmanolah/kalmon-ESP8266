cmds = triggerModules('_command_handlers')
cmds = tablesMerge(cmds)

handleCmd = function(cmd, data)
  local res = nil

  if cmd ~= nil and cmds[cmd] then
    print('CMD: Handling command:', cmd)

    local evt = {
      data = cjson.decode(data)
    }

    res = cmds[cmd](evt) or {}

    if (res ~= nil) and (type(res) == 'table') then
      if evt.data and evt.data.rid then
        res.rid = evt.data.rid
      end

      res = cjson.encode(res)
    end

    evt = nil
  end

  collectgarbage()

  return res
end
