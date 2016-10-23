local send_report = nil
local flush_data = nil

-- Init MQTT
mq_prefix = "/nodes/" .. node_id
mq = mqtt.Client(node_id, 120, cfg.data.mqtt_user, cfg.data.mqtt_password, 0)
mq_conn = false
mq_flushing = false
mq_data = {}

mq:lwt("/lwt", "offline", 0, 0)

mq:on("connect", function(conn)
  print("MQTT: Connected")
  mq_conn = true

  -- Subscribe to all command topics
  for cmd, cb in pairs(_k.cmds) do
    if cmd:sub(1, 1) ~= '/' then
      cmd = mq_prefix .. '/commands/' .. cmd
    end

    print('MQTT: Subscribing, topic:', cmd)
    mq:subscribe(cmd, 1, function(c) end)
  end

  send_report()
  collectgarbage()
end)

mq:on("offline", function(c)
  print("MQTT: Disconnected")
  mq_conn = false
end)

mq:on("message", function(c, topic, data)
  print("MQTT: Received, topic:", topic)
  local part = topic:sub(1, #mq_prefix + 1) == mq_prefix .. '/' and topic:sub(#mq_prefix + 1) or topic
  local cmd = part:match('/commands/(.+)') or part
  local res = _k.handle(cmd, cjson.decode(data))

  if res ~= nil then
    mq_data[#mq_data + 1] = { mq_prefix .. '/responses' .. part, cjson.encode(res) }
    if not mq_flushing then flush_data() end
  end

  cmd = nil
  part = nil
  res = nil
  collectgarbage()

  if data ~= nil then
    print("MQTT: Data:", data)
    queue_dsleep()
  end
end)

queue_dsleep = function (init)
  local act, _ = tmr.state(1)
  if (not act) and (not init) then
    return
  end

  -- Trigger dsleep in 5 seconds
  -- Delay if already called
  tmr.unregister(1)
  tmr.alarm(1, 5000, tmr.ALARM_SINGLE, function()
    if mq_conn then
      mq:close()
    end

    node.dsleep(cfg.data.report_interval * 1000 * 1000)
  end)
end

flush_data = function(cb)
  if #mq_data == 0 then
    mq_flushing = false
    if cb ~= nil then
      cb()
    end
  else
    mq_flushing = true
    local d = table.remove(mq_data)
    mq:publish(d[1], d[2], 0, 0, function(c)
      flush_data(cb)
    end)
  end
end

send_report = function()
  if not wifi.sta.getip() then
    print('Report: No Wifi')
    wifi.sta.connect()
  elseif not mq_conn then
    print('Report: No MQTT')
    mq:connect(cfg.data.mqtt_host, cfg.data.mqtt_port, cfg.data.mqtt_secure and 1 or 0)
  else
    print('Report: Sending..')
    mq_data = tablesMerge(_k.emit('_report'))

    for _, v in pairs(mq_data) do
      v[1] = mq_prefix .. v[1]
    end

    collectgarbage()
    flush_data(function()
      print('Report: Finished')
      queue_dsleep(cfg.data.sleep)
    end)
  end
end

-- Init WiFi
wifi.sleeptype(wifi.MODEM_SLEEP)
wifi.setphymode(wifi.PHYMODE_G)
wifi.setmode(wifi.STATION)

wifi.sta.eventMonReg(wifi.STA_GOTIP, function()
  print("WIFI: Connected")
  send_report()
end)

wifi.sta.eventMonReg(wifi.STA_CONNECTING, function()
  print("WIFI: Connecting..")
end)

if cfg.data.sta_ip and cfg.data.sta_gateway and cfg.data.sta_netmask then
  wifi.sta.setip({
    ip = cfg.data.sta_ip,
    netmask = cfg.data.sta_netmask,
    gateway = cfg.data.sta_gateway
  })
end

wifi.sta.eventMonStart(100)
wifi.sta.config(cfg.data.sta_ssid, cfg.data.sta_psk, 1)

-- Start report timer
tmr.alarm(0, cfg.data.report_interval * 1000, tmr.ALARM_AUTO, function()
  node.task.post(0, send_report)
  collectgarbage()
end)
