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

local voltage = adc.readvdd33()

local mq_client_id = "ESP-" .. node.chipid()
local mq = mqtt.Client(mq_client_id, 120, cfg.data.mqtt_user, cfg.data.mqtt_password)
local mq_connected = false
-- See http://www.hivemq.com/blog/mqtt-essentials-part-9-last-will-and-testament
mq:lwt("/lwt", "offline", 0, 0)
mq:on("connect", function(conn)
  mq_connected = true
  print("MQTT: Connected")

  -- mq:subscribe("/nodes/" .. mq_client_id .. "/commands", 0, 0)

  send_report()
  collectgarbage()
end)
mq:on("offline", function(conn)
  mq_connected = false
  print("MQTT: Disconnected")
end)
mq:on("message", function(conn, topic, data)
  print("MQTT: Received, topic:", topic)
  if data ~= nil then
    print("MQTT: Data:", data)
  end
end)

wifi.setphymode(wifi.PHYMODE_N)
wifi.setmode(wifi.STATION)
wifi.sta.config(cfg.data.sta_ssid, cfg.data.sta_psk)

queue_report = function()
  if cfg.data.sleep == '1' then
    if mq_connected then
      mq:close()
    end

    node.dsleep(tonumber(cfg.data.report_interval) * 1000 * 1000, 4)
  else
    tmr.stop(0)
    tmr.alarm(0, tonumber(cfg.data.report_interval) * 1000, 0, function()
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

    -- mq:connect(cfg.data.mqtt_host, tonumber(cfg.data.mqtt_port), cfg.data.mqtt_secure == '1', function(conn)
    --   send_report()
    --   collectgarbage()
    -- end)
    mq:connect(cfg.data.mqtt_host, tonumber(cfg.data.mqtt_port), cfg.data.mqtt_secure == '1')

    queue_report()
  else
    print('Report: Sending')

    mq:publish("/nodes/" .. mq_client_id .. "/sensors/battery", tostring(voltage), 0, 0, function(conn)
      queue_report()
    end)
  end
end

local tries = 0
local maxTries = 10

tmr.alarm(0, 1000, 1, function()
  local ip = wifi.sta.getip()

  if ip == nil and tries < maxTries then
    print('Wifi: Connecting..')
    tries = tries + 1
  else
    if tries == maxTries then
      print('Wifi: Connection failed')
    else
      print('Wifi: Connected, IP:', ip)
    end

    tmr.stop(0)
    tries = nil
    maxTries = nil
    collectgarbage()

    send_report()
  end
end)
