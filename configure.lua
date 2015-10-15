ap_cfg = {
  ssid = "ESP-" .. node.chipid(),
  auth = wifi.ap.AUTH_WPA2_PSK,
  pwd = cfg.data.ap_psk
}

wifi.setphymode(wifi.PHYMODE_G)
wifi.setmode(wifi.SOFTAP)
wifi.ap.config(ap_cfg)

dofile("httpserver.lc")(cfg.data.ws_port)
