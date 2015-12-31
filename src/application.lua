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

local mq_client_id = "ESP-" .. node.chipid()
local mq_prefix = "/nodes/" .. mq_client_id
local mq = mqtt.Client(mq_client_id, 120, cfg.data.mqtt_user, cfg.data.mqtt_password)
local mq_connected = false

mq_command_handlers = triggerModules('_command_handlers')
mq_command_handlers = tablesMerge(mq_command_handlers)

mq_report_data = {}
mq_report_step = 0

-- Register MQTT event handlers
-- See http://www.hivemq.com/blog/mqtt-essentials-part-9-last-will-and-testament
mq:lwt("/lwt", "offline", 0, 0)

mq:on("connect", function(conn)
  print("MQTT: Connected")
  mq_connected = true
  tmr.stop(0)

  -- Subscribe to all command topics
  for topic, handler in pairs(mq_command_handlers) do
    print('MQTT: Subscribing to topic:', topic)
    mq:subscribe(mq_prefix .. '/commands' .. topic, 0, function(conn) end)
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
  local cmd = topic:match('/commands(/.+)')

  if cmd ~= nil and mq_command_handlers[cmd] then
    print('CMD: Handling command:', cmd)
    local cmd_evt = {
      data = cjson.decode(data)
    }

    mq_command_handlers[cmd](cmd_evt)
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

queue_report = function()
  mq_report_step = 0
  mq_report_data = {}

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
    if mq_report_step > 0 and mq_report_step >= #mq_report_data then
      print('Report: Finished')
      queue_report()
    else
      if mq_report_step == 0 then
        print('Report: Sending..')

        mq_report_data = triggerModules('report_data')
        mq_report_data = tablesMerge(mq_report_data)

        collectgarbage()
      end

      mq_report_step = mq_report_step + 1
      local data = mq_report_data[mq_report_step]

      if data then
        mq:publish(mq_prefix .. data[1], data[2], 0, 0, function(conn)
          send_report()
        end)
      else
        send_report()
      end

      data = nil
      collectgarbage()
    end
  end
end
