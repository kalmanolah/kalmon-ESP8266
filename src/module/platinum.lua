-- This module provides periodic status data extracted from a
-- Diehl AKO Stiftung & Co. KG Photovoltaics PLATINUM Bus
-- See: http://www.diehl.com/en/diehl-controls/photovoltaics/platinum-downloads.html
-- See: https://groups.google.com/forum/#!topic/websolarlog/h-dNpae2tLU
-- Deps: UART, struct, crc16
-- Status: WIP
platinum = {
  CMD_STATUS = '\18',
  CMD_DAILY = '\19',
  buffer = {},

  encode_payload = function (data)
    local res = struct.pack('c2Bc0', '\45\19', #data, data)
    res = res .. struct.pack('I2', crc16.calc(res, nil, true))

    return res
  end,

  generate_payload = function (cmd)
    local data = struct.pack('c1', cmd)

    if cmd == platinum.CMD_STATUS then
      data = data .. struct.pack('c5', tostring(tmr.now()):sub(-5))
    end

    return platinum.encode_payload(data)
  end,

  bits = function (num)
    local t={}
    while num>0 do
        rest=num%2
        table.insert(t,1,rest)
        num=(num-rest)/2
    end
    return table.concat(t)
  end,

  decode_payload = function (payload)
    local stx, data, crc = struct.unpack('c2Bc0I2', payload)
    local res = {
      raw = payload,
      cmd = data:sub(1, 1)
    }

    -- Verify CRC
    if crc16.calc(payload:sub(1, -3), nil, true) == crc then
      if res.cmd == platinum.CMD_STATUS then
        res.cmd,
        res.hour, res.minute, res.second,
        res.status, res.event,
        res.voltage_dc, res.current_dc, res.power_dc,
        res.voltage_ac, res.current_ac, res.power_ac,
        res.energy_day,
        res.temp_1, res.temp_2, res.temp_3,
        res.unknown = struct.unpack('BI1I1I1BBI2I1I2I2I1I2I4I1I1I1c2', data)
      end
    end

    return res
  end
}

_k.on('_init', function ()
  uart.setup(0, 19200, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)
end)

_k.on('_report', function ()
  uart.write(0, platinum.generate_payload(platinum.CMD_STATUS))
  uart.on('data', 0, function (data)
    platinum.buffer = platinum.decode_payload(data)
    uart.on('data')
  end, 0)

  if #platinum.buffer then
    return {
      { "/platinum/status", platinum.buffer }
    }
  end
end)
