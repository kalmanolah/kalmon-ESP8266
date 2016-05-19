if file.open('main.lua') then
  file.close()
  dofile('main.lua')
else
  dofile('main.lc')
end
