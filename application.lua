if not cfg.data.sta_ssid then
  print('Wifi: Missing config')
  return
end

if (not cfg.data.mqtt_user) or (not cfg.data.mqtt_password) then
  print('MQTT: Missing config')
  return
end

local mq = mqtt.Client("ESP-" .. node.chipid(), 120, cfg.data.mqtt_user, cfg.data.mqtt_pass)
local mq_connected = false
-- See http://www.hivemq.com/blog/mqtt-essentials-part-9-last-will-and-testament
mq:lwt("/lwt", "offline", 0, 0)
mq:on("connect", function(con)
  mq_connected = true
  print("MQTT: Connected")
end)
mq:on("offline", function(con)
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

local send_report = function()
  if not wifi.sta.getip() then
    print('Report: Skipping, no Wifi')
    return
  end

  if not mq_connected then
    print('Report: Skipping, no MQTT')
    return
  end

  -- mq:connect(cfg.data.mqtt_host, tonumber(cfg.data.mqtt_port), cfg.data.mqtt_secure == '1', function(conn)
  --   -- Possibly send data here, for temporary connections?
  --   mq:close()
  -- end)

  -- Send data here someday..
  -- -- subscribe topic with qos = 0
  -- m:subscribe("/topic",0, function(conn) print("subscribe success") end)

  -- -- publish a message with data = hello, QoS = 0, retain = 0
  -- m:publish("/topic","hello",0,0, function(conn) print("sent") end)
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

      local tries = 0
      local maxTries = 10

      mq:connect(cfg.data.mqtt_host, tonumber(cfg.data.mqtt_port), cfg.data.mqtt_secure == '1', function(conn) end)

      tmr.alarm(1, 1000, 1, function()
        if (not mq_connected) and tries < maxTries then
          print('MQTT: Connecting..')
          tries = tries + 1
        else
          if tries == maxTries then
            print('MQTT: Connection failed')
          end

          tmr.stop(1)
          tries = nil
          maxTries = nil
          collectgarbage()

          if not not cfg.data.report_queued then
            cfg.data.report_queued = false
            cfg.save()
          end

          send_report()

          if cfg.data.sleep == '1' then
            cfg.data.report_queued = true
            cfg.save()
            mq:close()
            node.dsleep(tonumber(cfg.data.report_interval) * 1000 * 1000, 4)
          else
            tmr.alarm(0, tonumber(cfg.data.report_interval) * 1000, 1, function()
              send_report()
              collectgarbage()
            end)
          end
        end
      end)
    end

    tmr.stop(0)
    tries = nil
    maxTries = nil
    collectgarbage()
  end
end)
