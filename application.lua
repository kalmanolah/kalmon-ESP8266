if not not cfg.data.sta_ssid then
  wifi.setphymode(wifi.PHYMODE_N)
  wifi.setmode(wifi.STATION)
  wifi.sta.config(cfg.data.sta_ssid, cfg.data.sta_psk)

  local joinCounter = 0
  local joinMaxAttempts = 5

  tmr.alarm(0, 3000, 1, function()
    local ip = wifi.sta.getip()

    if ip == nil and joinCounter < joinMaxAttempts then
      print('Wifi: Connecting..')
      joinCounter = joinCounter +1
    else
      if joinCounter == joinMaxAttempts then
         print('Wifi: Connection failed')
      else
         print('Wifi: Connected, IP:', ip)
      end

      tmr.stop(0)
      joinCounter = nil
      joinMaxAttempts = nil
      collectgarbage()
    end
  end)
else
  print('Wifi: Missing config')
end
