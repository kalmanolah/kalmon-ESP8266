if not cfg.data.sta_ssid then
  print('Wifi: Missing config')
  return
end

if (not cfg.data.mqtt_user) or (not cfg.data.mqtt_password) then
  print('MQTT: Missing config')
  return
end

local queue_report = nil
local send_report = nil
local flush_data = nil

mq_id = "ESP-" .. node.chipid()
local mq_prefix = "/nodes/" .. mq_id
local mq = mqtt.Client(mq_id, 120, cfg.data.mqtt_user, cfg.data.mqtt_password)
local mq_connected = false

mq_cmds = triggerModules('_command_handlers')
mq_cmds = tablesMerge(mq_cmds)

mq_data = {}
mq_data_ptr = 0
mq_report_step = 0

-- Register MQTT event handlers
-- See http://www.hivemq.com/blog/mqtt-essentials-part-9-last-will-and-testament
mq:lwt("/lwt", "offline", 0, 0)

mq:on("connect", function(conn)
  print("MQTT: Connected")
  mq_connected = true
  tmr.stop(0)

  -- Subscribe to all command topics
  for topic, handler in pairs(mq_cmds) do
    if topic:sub(1, 1) ~= '/' then
      topic = mq_prefix .. '/commands/' .. topic
    end

    print('MQTT: Subscribing to topic:', topic)
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

  -- If this is a command, try to have it handled
  local cmd = topic:match('/commands/(.+)') or topic

  if cmd ~= nil and mq_cmds[cmd] then
    print('CMD: Handling command:', cmd)
    local cmd_evt = {
      data = cjson.decode(data)
    }

    local cmd_res = mq_cmds[cmd](cmd_evt)

    if cmd_res ~= nil then
      if type(cmd_res) == 'table' then
        if cmd_evt.data and cmd_evt.data.rid then
          cmd_res.rid = cmd_evt.data.rid
        end

        cmd_res = cjson.encode(cmd_res)
      end

      mq_data[#mq_data + 1] = { topic .. '/responses', cmd_res }
      flush_data()
    end

    cmd_res = nil
    cmd_evt = nil
  end

  cmd = nil
  collectgarbage()

  if data ~= nil then
    print("MQTT: Data:", data)
  end
end)

wifi.setphymode(wifi.PHYMODE_N)
wifi.setmode(wifi.STATION)
wifi.sta.eventMonReg(wifi.STA_GOTIP, function()
  -- wifi.sta.eventMonReg(wifi.STA_GOTIP, "unreg")
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
  if not wifi.sta.getip() then
    print('Report: Skipping, no Wifi')
    queue_report()
  elseif not mq_connected then
    print('Report: Skipping, no MQTT')
    mq:connect(cfg.data.mqtt_host, cfg.data.mqtt_port, cfg.data.mqtt_secure)

    -- Wait a second for MQTT connection
    tmr.alarm(0, 1000, 0, function()
      queue_report()
    end)
  else
    print('Report: Sending..')
    mq_data = triggerModules('_report_data')
    mq_data = tablesMerge(mq_data)

    collectgarbage()

    flush_data(function()
      print('Report: Finished')
      queue_report()
    end)
  end
end
