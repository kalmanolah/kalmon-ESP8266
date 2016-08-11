-- Atlas Scientific EZO (tm) pH module
-- http://atlas-scientific.com/product_pages/circuits/ezo_ph.html
ezoph = {
  sda = nil,
  scl = nil,
  cmd = function(cmd)
    if not (ezoph.sda and ezoph.scl) then
      return
    end

    local id = 0
    local d = 0x63
    local r = nil

    i2c.setup(id, ezoph.sda, ezoph.scl, i2c.SLOW)
    i2c.start(id)
    i2c.address(id, d, i2c.TRANSMITTER)
    i2c.write(id, cmd)
    i2c.stop(id)

    tmr.delay(1000000)

    i2c.start(id)
    i2c.address(id, d, i2c.RECEIVER)
    r = i2c.read(id, 20)
    i2c.stop(id)

    -- if r:byte(1) ~= 1 then
    --   r = nil
    -- end

    return r
  end
}

_k.on('_cfg.fields', function ()
  return {
    ezoph_sda_pin = {
      type = 'number',
      default = false
    },
    ezoph_scl_pin = {
      type = 'number',
      default = false
    }
  }
end)

_k.on('_init', function ()
  ezoph.sda = cfg.data.ezoph_sda_pin
  ezoph.scl = cfg.data.ezoph_scl_pin
  -- ezoph.cmd('L,0')
end)

_k.on('_report', function ()
  local r = ezoph.cmd('R')
  ezoph.cmd('SLEEP')

  if r ~= nil then
    return {{ "/sensors/ezoph/ph", r }}
  end
end)

_k.cmd('ezoph/calibrate', function (e)
  local ph = e.ph or 7
  local lvl = e.lvl or 'mid'
  ezoph.cmd('Cal,'..lvl..','..ph..'.00')
  ezoph.cmd('SLEEP')
end)
