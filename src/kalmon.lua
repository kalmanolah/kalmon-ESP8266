_k = {
  evts = {},
  cmds = {},

  on = function (e, clbk)
    if not _k.evts[e] then
      _k.evts[e] = {}
    end

    table.insert(_k.evts[e], clbk)
  end,

  emit = function (e, data)
    local r = {}

    if _k.evts[e] then
      for _, clbk in pairs(_k.evts[e]) do
        r[#r+1] = clbk(data)
      end
    end

    collectgarbage()
    return r
  end,

  cmd = function (e, clbk)
    _k.cmds[e] = clbk
  end,

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
