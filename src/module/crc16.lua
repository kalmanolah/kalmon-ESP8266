crc16 = {
  POLY = 0x1021,
  init = function (c)
    local r = 0
    c = bit.lshift(c, 8)
    for i = 0, 7 do
      if bit.band(bit.bxor(r, c), 0x8000) > 0 then
        r = bit.bxor(bit.lshift(r, 1), crc16.POLY)
      else
        r = bit.lshift(r, 1)
      end
      c = bit.lshift(c, 1)
    end
    return r
  end,
  calc = function (b, init, rev)
    r = init or 0xffff
    local c = nil
    local idx = nil

    for i = 1, #b do
      c = bit.band(b:byte(i, i), 0xff)
      idx = bit.bxor(c, bit.rshift(bit.band(r, 0xffff), 8))
      idx = bit.band(idx, 0xffff)
      r = bit.bxor(crc16.init(idx), bit.lshift(bit.band(r, 0xffff), 8))
      r = bit.band(r, 0xffff)
    end

    if rev then
      r = bit.bxor(bit.lshift(bit.band(r, 0xff), 8), bit.rshift(bit.band(r, 0xffff), 8))
    end

    return r
  end
}
