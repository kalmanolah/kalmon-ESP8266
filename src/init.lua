if file.open('main.lc') then
  file.close('main.lc')
  dofile('main.lc')
else
  dofile('main.lua')
end
