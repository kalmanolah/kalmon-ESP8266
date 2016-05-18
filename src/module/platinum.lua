-- This module provides periodic status data extracted from a
-- Diehl AKO Stiftung & Co. KG Photovoltaics PLATINUM Bus
-- See: http://www.diehl.com/en/diehl-controls/photovoltaics/platinum-downloads.html
-- See: https://groups.google.com/forum/#!topic/websolarlog/h-dNpae2tLU
-- Deps: UART, ow, struct
-- Status: WIP
local obj = {}

local CMD_STATUS = '\18'

local encode_payload = function (data)
  local res = struct.pack('c2Bc0', '\45\19', #data, data)
  res = res .. struct.pack('I2', ow.crc16(res))

  return res
end

local generate_payload = function (cmd)
  local data = struct.pack('B', cmd)

  if cmd == CMD_STATUS then
    data = data .. struct.pack('c5', tostring(tmr.now()):sub(-5))
  end

  return encode_payload(data)
end

local decode_payload = function (payload)
  local stx, len, data, crc = struct.unpack('c2Bc0I2', payload)
  local res = {
    raw = payload
    cmd = data:sub(1, 1)
  }

  -- Verify CRC
  if ow.crc16(payload:sub(1, -3)) == crc then
    if cmd == CMD_STATUS then
      res.hour, res.minute, res.second,
      res.status, res.event,
      res.voltage_dc, res.current_dc, res.power_dc,
      res.voltage_ac, res.current_ac, res.power_ac,
      res.energy_day,
      res.temp_1, res.temp_2, res.temp_3,
      res.unknown = struct.unpack('I1I1I1BBI2I1I2I2I1I2I4I1I1I1c2', data)
    end
  end

  return res
end

obj._init = function ()
  sess.platinum_buffer = {}
  uart.setup(0, 19200, 8, uart.PARITY_NONE, uart.STOPBITS_1, 1)
end

obj._report_data = function()
  uart.write(0, generate_payload(CMD_STATUS))
  uart.on('data', 0, function (data)
    sess.platinum_buffer = decode_payload(data)
    uart.on('data')
  end, 0)

  return {
    { "/platinum/bus/status", sess.platinum_buffer }
  }
end

return makeModule(obj)
