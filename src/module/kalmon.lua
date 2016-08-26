-- This module adds core functionality.
_k.on('_init', function ()
  cfg = {
    data = {},
    file = 'settings.json'
  }

  _k.emit('_cfg.load')
end)

_k.on('_report', function ()
  return {
    {'/heartbeat', 'ping'}
  }
end)

_k.on('_cfg.load', function ()
  if file.open(cfg.file, 'r') then
    local data = file.read()

    if data ~= nil and data ~= 'null' then
      cfg.data = cjson.decode(data)
    end

    file.close()
  end

  -- Populate empty fields with default data
  local fields = tablesMerge(_k.emit('_cfg.fields'))
  for k, v in pairs(fields) do
    if cfg.data[k] == nil then
      cfg.data[k] = v.default
    end
  end
end)
_k.on('_cfg.save', function ()
  file.open(cfg.file, 'w+')
  file.write(cjson.encode(cfg.data))
  file.close()
end)
_k.on('_cfg.fields', function ()
  return {
    sta_ssid = {
      type = 'text',
      default = false
    },
    sta_psk = {
      type = 'text',
      default = false
    },
    sta_ip = {
      type = 'text',
      default = false
    },
    sta_netmask = {
      type = 'text',
      default = false
    },
    sta_gateway = {
      type = 'text',
      default = false
    },
    ap_psk = {
      type = 'text',
      default = 'ESP-8266'
    },
    ws_port = {
      type = 'number',
      min = '1',
      max = '65535',
      default = 80
    },
    cfg_pin = {
      type = 'number',
      default = 4
    },
    mqtt_user = {
      type = 'text',
      default = 'user'
    },
    mqtt_password = {
      type = 'text',
      default = 'password'
    },
    mqtt_host = {
      type = 'text',
      default = 'mqtt.local'
    },
    mqtt_port = {
      type = 'number',
      min = '1',
      max = '65535',
      default = 1337
    },
    mqtt_secure = {
      type = 'boolean',
      default = false
    },
    sleep = {
      type = 'boolean',
      default = false
    },
    report_interval = {
      type = 'number',
      min = '30',
      max = '604800',
      default = 60
    }
  }
end)

_k.cmd('info', function ()
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
end)

-- Absolute, for node discovery
_k.cmd('/ping', function ()
  return {node = node_id}
end)
_k.cmd('restart', function ()
  -- Delay a bit to allow for proper ACK
  tmr.alarm(2, 1000, 0, node.restart)
end)

_k.cmd('cfg/set', function (e)
  cfg.data[e.key] = e.value
  _k.emit('_cfg.save')
end)

_k.cmd('files/remove', function (e)
  file.remove(e.file)
end)
_k.cmd('files/create', function (e)
  local offset = e.offset or 0
  local mode = offset == 0 and 'w+' or 'a'

  file.open(e.file, mode)
  file.seek('set', offset)
  file.write(e.content)
  file.close()

  if e.compile then
    compileAndRemoveFile(e.file)
  end
end)
