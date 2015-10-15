return function (connection, req, args)
  if req.method == "POST" then
    local rd = req.getRequestData()

    for k, v in pairs(rd) do
      cfg.data[k] = v
    end

    cfg.save()
  end

  connection:send("HTTP/1.0 200 OK\r\nContent-Type: text/html\r\nCache-Control: private, no-store\r\n\r\n")
  connection:send('<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Settings</title></head><body>')
  connection:send('<form method="POST">')
  connection:send('Wifi SSID:<br><input type="text" name="sta_ssid" value="' .. string.gsub(cfg.data.sta_ssid, '"', '&quot;') .. '"><br>')
  connection:send('Wifi PSK:<br><input type="text" name="sta_psk" value="' .. string.gsub(cfg.data.sta_psk, '"', '&quot;') .. '"><br>')
  connection:send('<input type="submit" value="submit"></form></body></html>')
end
