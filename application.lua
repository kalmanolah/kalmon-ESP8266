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
local mq_prefix = "/nodes/" .. mq_client_id
local mq = mqtt.Client(mq_client_id, 120, cfg.data.mqtt_user, cfg.data.mqtt_password)
local mq_connected = false
-- See http://www.hivemq.com/blog/mqtt-essentials-part-9-last-will-and-testament
mq:lwt("/lwt", "offline", 0, 0)
mq:on("connect", function(conn)
  mq_connected = true
  tmr.stop(0)
  print("MQTT: Connected")

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
  if cfg.data.sleep == '0' then
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
    mq:connect(cfg.data.mqtt_host, tonumber(cfg.data.mqtt_port), cfg.data.mqtt_secure == '1')

    -- Wait a second for MQTT connection
    tmr.alarm(0, 1000, 0, function()
      queue_report()
    end)
  else
    print('Report: Sending')
    mq:publish(mq_prefix .. "/battery/voltage", tostring(voltage), 0, 0, function(conn)
      local dht_pin = 3
      gpio.mode(dht_pin, gpio.INPUT)
      local status, temp, hum, temp_dec, hum_dec = dht.read(dht_pin)

      if status == dht.OK then
        mq:publish(mq_prefix .. "/sensors/temperature", string.format("%d.%03d", math.floor(temp), temp_dec), 0, 0, function(conn)
          mq:publish(mq_prefix .. "/sensors/humidity", string.format("%d.%03d", math.floor(hum), hum_dec), 0, 0, function(conn)
            queue_report()
          end)
        end)
      else
        if status == dht.ERROR_CHECKSUM then
          print("DHT Checksum error.")
        elseif status == dht.ERROR_TIMEOUT then
          print("DHT Timeout.")
        end

        queue_report()
      end
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
