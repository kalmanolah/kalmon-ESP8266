local send_report = function()
  print('Report: Sending')
  -- Report sending code goes here
end

if not not cfg.data.sta_ssid then
  wifi.setphymode(wifi.PHYMODE_N)
  wifi.setmode(wifi.STATION)
  wifi.sta.config(cfg.data.sta_ssid, cfg.data.sta_psk)

  local tries = 0
  local maxTries = 10

  tmr.alarm(0, 1000, 1, function()
    local ip = wifi.sta.getip()

    if ip == nil and tries < maxTries then
      print('Wifi: Connecting..')
      tries = tries +1
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

      cfg.data.report_queued = false
      cfg.save()
      send_report()

      if cfg.data.sleep == '1' then
        cfg.data.report_queued = true
        cfg.save()
        node.dsleep(tonumber(cfg.data.report_interval) * 1000 * 1000, 4)
      else
        tmr.alarm(0, tonumber(cfg.data.report_interval) * 1000, 1, send_report)
      end
    end
  end)
else
  print('Wifi: Missing config')
end
