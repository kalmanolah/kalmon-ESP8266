_k = {
  evts = {},
  cmds = {},

  -- Register event handler
  on = function (e, cb)
    if not _k.evts[e] then
      _k.evts[e] = {}
    end

    table.insert(_k.evts[e], cb)
  end,

  -- Handle event
  emit = function (e, data)
    local r = {}

    if _k.evts[e] then
      for _, cb in pairs(_k.evts[e]) do
        r[#r+1] = cb(data)
      end
    end

    collectgarbage()
    return r
  end,

  -- Register command handler
  cmd = function (e, cb)
    _k.cmds[e] = cb
  end,

  -- Handle command
  handle = function (e, data)
    local r = nil

    if _k.cmds[e] then
      r = _k.cmds[e](data) or {}
    end

    if type(r) == 'table' and type(data) == 'table' and data.rid then
      r.rid = data.rid
    end

    collectgarbage()
    return r
  end
}
