uart.setup(0, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1, 1) -- Lock rate

if file.open('main.lua') then
  file.close()
  dofile('main.lua')
else
  dofile('main.lc')
end
