local ap_cfg = {
  ssid = "ESP-" .. node.chipid(),
  auth = wifi.ap.AUTH_WPA2_PSK,
  pwd = cfg.data.ap_psk
}

wifi.setphymode(wifi.PHYMODE_G)
wifi.setmode(wifi.SOFTAP)
wifi.ap.config(ap_cfg)

ap_cfg = nil
collectgarbage()

srv = net.createServer(net.TCP)
srv:listen(cfg.data.ws_port, function(conn)
  conn:on("receive", function(conn, payload)
    local data = cjson.decode(payload)
    local res = handleCmd(data.cmd, data.data)

    if res ~= nil then
        conn:send(res)
    end

    data = nil
    res = nil
    collectgarbage()
  end)

  conn:on("sent", function(conn)
    conn:close()
  end)
end)
