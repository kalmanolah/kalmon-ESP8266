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

local srv = net.createServer(net.TCP)
srv:listen(cfg.data.ws_port, function(conn)
  conn:on("receive", function(conn, payload)
    local data = cjson.decode(payload)
    local res = _k.handle(data.cmd, cjson.decode(data.data))

    if res ~= nil then
      conn:send(cjson.encode(res))
    end
  end)

  conn:on("sent", function(conn)
    conn:close()
  end)
end)
