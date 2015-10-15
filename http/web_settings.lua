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
  connection:send('Wifi SSID:<br><input required type="text" name="sta_ssid" value="' .. string.gsub(cfg.data.sta_ssid, '"', '&quot;') .. '"><br>')
  connection:send('Wifi PSK:<br><input required type="text" name="sta_psk" value="' .. string.gsub(cfg.data.sta_psk, '"', '&quot;') .. '"><br>')
  connection:send('Report interval (seconds):<br><input required type="number" min="1" max="99999" name="report_interval" value="' .. cfg.data.report_interval .. '"><br>')
  connection:send('Deep sleep (between reports)?:<br><select required name="sleep">')
  connection:send('<option value="0" ' .. (cfg.data.sleep == '0' and 'selected' or '') .. '>No</option>')
  connection:send('<option value="1" ' .. (cfg.data.sleep == '1' and 'selected' or '') .. '>Yes</option>')
  connection:send('</select><br>')
  connection:send('MQTT user:<br><input required type="text" name="mqtt_user" value="' .. string.gsub(cfg.data.mqtt_user, '"', '&quot;') .. '"><br>')
  connection:send('MQTT password:<br><input required type="text" name="mqtt_password" value="' .. string.gsub(cfg.data.mqtt_password, '"', '&quot;') .. '"><br>')
  connection:send('MQTT host:<br><input required type="text" name="mqtt_host" value="' .. string.gsub(cfg.data.mqtt_host, '"', '&quot;') .. '"><br>')
  connection:send('MQTT port:<br><input required type="number" name="mqtt_port" min="1" max="65535" value="' .. cfg.data.mqtt_port .. '"><br>')
  connection:send('MQTT SSL/TLS?:<br><select required name="mqtt_secure">')
  connection:send('<option value="0" ' .. (cfg.data.mqtt_secure == '0' and 'selected' or '') .. '>No</option>')
  connection:send('<option value="1" ' .. (cfg.data.mqtt_secure == '1' and 'selected' or '') .. '>Yes</option>')
  connection:send('</select><br>')
  connection:send('<input type="submit" value="submit"></form></body></html>')
end
