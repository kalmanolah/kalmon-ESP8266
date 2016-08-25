-- Atlas Scientific EZO (tm) ORP module
-- http://atlas-scientific.com/product_pages/circuits/ezo_orp.html
ezoorp = {
  sda = nil,
  scl = nil,
  cmd = function(cmd)
    if not (ezoorp.sda and ezoorp.scl) then
      return
    end

    local id = 0
    local d = 0x62
    local r = nil

    i2c.setup(id, ezoorp.sda, ezoorp.scl, i2c.SLOW)
    i2c.start(id)
    i2c.address(id, d, i2c.TRANSMITTER)
    i2c.write(id, cmd)
    i2c.stop(id)

    tmr.delay(1000000)
    tmr.wdclr()

    i2c.start(id)
    i2c.address(id, d, i2c.RECEIVER)
    r = i2c.read(id, 10)
    i2c.stop(id)

    if r:byte(1) == 1 then
      r = r:sub(2)
    elseif r:byte(1) == 255 then
      r = nil
    end

    return r
  end
}

_k.on('_cfg.fields', function ()
  return {
    ezoorp_sda_pin = {
      type = 'number',
      default = false
    },
    ezoorp_scl_pin = {
      type = 'number',
      default = false
    }
  }
end)

_k.on('_init', function ()
  ezoorp.sda = cfg.data.ezoorp_sda_pin
  ezoorp.scl = cfg.data.ezoorp_scl_pin
  ezoorp.cmd('L,0')
end)

_k.on('_report', function ()
  local r = ezoorp.cmd('R')
  -- ezoorp.cmd('SLEEP')

  if r ~= nil then
    return {{ "/sensors/ezoorp/orp", r }}
  end
end)

_k.cmd('ezoorp/calibrate', function (e)
  local v = e.orp or 0
  ezoorp.cmd(string.format("Cal,%d.%03d", math.floor(v / 1000), v - ((v / 1000) * 1000)))
  -- ezoorp.cmd('SLEEP')
end)
