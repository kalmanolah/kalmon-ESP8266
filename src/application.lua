if not cfg.data.sta_ssid then
  print('Wifi: No config')
  return
end

if (not cfg.data.mqtt_user) or (not cfg.data.mqtt_password) then
  print('MQTT: No config')
  return
end

local queue_report = nil
local send_report = nil
local flush_data = nil

local mq_prefix = "/nodes/" .. node_id
local mq = mqtt.Client(node_id, 120, cfg.data.mqtt_user, cfg.data.mqtt_password)
local mq_connected = false

mq_data = {}
mq_data_ptr = 0

-- Register MQTT event handlers
mq:lwt("/lwt", "offline", 0, 0)

mq:on("connect", function(conn)
  print("MQTT: Connected")
  mq_connected = true

  -- Subscribe to all command topics
  for topic, handler in pairs(cmds) do
    if topic:sub(1, 1) ~= '/' then
      topic = mq_prefix .. '/commands/' .. topic
    end

    print('MQTT: Subscribing, topic:', topic)
    mq:subscribe(topic, 0, function(conn) end)
  end

  send_report()
  collectgarbage()
end)

mq:on("offline", function(conn)
  print("MQTT: Disconnected")
  mq_connected = false
end)

mq:on("message", function(conn, topic, data)
  print("MQTT: Received, topic:", topic)

  local part = topic:sub(1, #mq_prefix + 1) == mq_prefix .. '/' and topic:sub(#mq_prefix + 1) or topic
  local cmd = part:match('/commands/(.+)') or part
  local res = handleCmd(cmd, data)

  if res ~= nil then
    mq_data[#mq_data + 1] = { mq_prefix .. '/responses' .. part, res }
    flush_data()
  end

  cmd = nil
  part = nil
  res = nil
  collectgarbage()

  if data ~= nil then
    print("MQTT: Data:", data)
  end
end)

wifi.setphymode(wifi.PHYMODE_N)
wifi.setmode(wifi.STATION)
wifi.sta.eventMonReg(wifi.STA_GOTIP, function()
  wifi.sta.eventMonStop("unreg all")
  print("WIFI: Connected")
  send_report()
end)

print("WIFI: Connecting..")
wifi.sta.eventMonStart()
wifi.sta.config(cfg.data.sta_ssid, cfg.data.sta_psk)

flush_data = function(callback)
  mq_data_ptr = mq_data_ptr + 1

  if mq_data_ptr > #mq_data then
    mq_data = {}
    mq_data_ptr = 0

    if callback ~= nil then
      callback()
    end
  else
    local d = mq_data[mq_data_ptr]

    mq:publish(d[1], d[2], 0, 0, function(conn)
      flush_data(callback)
    end)

    d = nil
  end

  collectgarbage()
end

queue_report = function()
  if cfg.data.sleep then
    if mq_connected then
      mq:close()
    end

    node.dsleep(cfg.data.report_interval * 1000 * 1000, 4)
  else
    tmr.stop(0)
    tmr.alarm(0, cfg.data.report_interval * 1000, 0, function()
      send_report()
      collectgarbage()
    end)
  end
end

send_report = function()
  if not cfg.data.sleep then
    queue_report()
  end

  if not wifi.sta.getip() then
    print('Report: No Wifi')
    if cfg.data.sleep then
      queue_report()
    end
  elseif not mq_connected then
    print('Report: No MQTT')
    mq:connect(cfg.data.mqtt_host, cfg.data.mqtt_port, cfg.data.mqtt_secure)
  else
    print('Report: Sending..')
    mq_data = triggerModules('_report_data')
    mq_data = tablesMerge(mq_data)

    collectgarbage()
    flush_data(function()
      print('Report: Finished')
      if cfg.data.sleep then
        queue_report()
      end
    end)
  end
end
