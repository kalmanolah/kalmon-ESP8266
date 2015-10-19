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
mq_report_step = 0
mq_report_sources = {}
mq_report_data = {}

-- Register MQTT report data sources
mq_report_sources[1] = function()
  return {
    { "/battery/voltage", tostring(voltage) }
  }
end
mq_report_sources[2] = function()
  local dht_pin = 3
  gpio.mode(dht_pin, gpio.INPUT)
  local status, temp, hum, temp_dec, hum_dec = dht.read(dht_pin)

  if status == dht.OK then
    return {
      { "/sensors/temperature", string.format("%d.%03d", math.floor(temp), temp_dec) },
      { "/sensors/temperature", string.format("%d.%03d", math.floor(hum), hum_dec) }
    }
  else
    if status == dht.ERROR_CHECKSUM then
      print("DHT Checksum error.")
    elseif status == dht.ERROR_TIMEOUT then
      print("DHT Timeout.")
    end

    return nil
  end
end

-- Register MQTT event handlers
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
  mq_report_step = 0
  mq_report_data = {}

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
    mq:connect(cfg.data.mqtt_host, tonumber(cfg.data.mqtt_port), cfg.data.mqtt_secure == '1')

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
        print('Report: Sending')
        for i, source in pairs(mq_report_sources) do
          local results = source()
          for i, result in pairs(results) do
            mq_report_data[#mq_report_data + 1] = result
          end
        end
      end

      mq_report_step = mq_report_step + 1
      local result = mq_report_data[mq_report_step]

      if result then
        mq:publish(mq_prefix .. result[1], result[2], 0, 0, function(conn)
          send_report()
        end)
      end
    end
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
