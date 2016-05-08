-- This module adds some core functionality.
-- See https://github.com/kalmanolah/kalmon-ESP8266
-- See https://github.com/kalmanolah/kalmon-web
local obj = {}

obj._report_data = function()
  return {
    { "/heartbeat", "ping" }
  }
end

obj._command_handlers = function()
  local handlers = {}

  handlers['/ping'] = function(evt)
    return {
      node = node_id,
    }
  end

  handlers['info'] = function(evt)
    local files = {}
    local v_major, v_minor, v_dev, chip_id, flash_id, flash_size, flash_mode, flash_speed = node.info()
    local fs_r, fs_u, fs_t = file.fsinfo()

    for f, s in pairs(file.list()) do
      files[#files + 1] = {f, s}
    end

    return {
      node = node_id,
      files = files,
      cfg = cfg.data,
      stats = {
        version = v_major..'.'..v_minor..'.'..v_dev,
        chip_id = chip_id,
        flash_id = flash_id,
        heap_left = node.heap(),
        fs_left = fs_r,
        fs_used = fs_u,
        fs_total = fs_t
      }
    }
  end

  handlers['restart'] = function(evt)
    node.restart()
  end

  handlers['cfg/set'] = function(evt)
    cfg.data[evt.data.key] = evt.data.value
    triggerModule('settings', 'save')
  end

  handlers['files/remove'] = function(evt)
    file.remove(evt.data.file)
  end

  handlers['files/create'] = function(evt)
    local offset = evt.data.offset or 0
    local mode = offset == 0 and 'w+' or 'a'

    file.open(evt.data.file, mode)
    file.seek('set', offset)
    file.write(evt.data.content)
    file.close()

    if evt.data.compile then
      compileAndRemoveFile(evt.data.file)
    end

    local offset = nil
    local mode = nil
  end

  return handlers
end

return makeModule(obj)
