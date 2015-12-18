return function (connection, req, args)
  if req.method == "POST" then
    local rd = req.getRequestData()

    for k, v in pairs(rd) do
      if cfg.fields[k].type == 'number' then
        v = tonumber(v)
      elseif cfg.fields[k].type == 'boolean' then
        v = v == '1'
      end

      cfg.data[k] = v
    end

    cfg.save()
  end

  connection:send("HTTP/1.0 200 OK\r\nContent-Type: text/html\r\nCache-Control: private, no-store\r\n\r\n")
  connection:send('<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Settings</title></head><body>')
  connection:send('<form method="POST">')

  for k, v in pairs(cfg.fields) do
    connection:send('<div class="form-group">')
    connection:send('<label for="' .. k .. '">' .. (v.label or k) .. '</label>')

    if v.type == 'boolean' then
      connection:send('<select name="' .. k .. '" id="' .. k .. '" ' .. (v.required and 'required' or '') .. '>')
      connection:send('<option ' .. ((not cfg.data[k]) and 'selected' or '') .. ' value="0">No</option>')
      connection:send('<option ' .. (cfg.data[k] and 'selected' or '') .. ' value="1">Yes</option>')
      connection:send('</select>')
    elseif v.type == 'number' then
      connection:send('<input value="' .. string.gsub(cfg.data[k] or '', '"', '&quot;') .. '" name="' .. k .. '" id="' .. k .. '" ' .. (v.required and 'required ' or '') .. (v.min and 'min="' .. v.min .. '" ' or '')  .. (v.max and 'max="' .. v.max .. '" ' or '') .. ' type="number">')
    else
      connection:send('<input value="' .. string.gsub(cfg.data[k] or '', '"', '&quot;') .. '" name="' .. k .. '" id="' .. k .. '" ' .. (v.required and 'required ' or '') .. ' type="' .. (v.type or 'text') .. '">')
    end

    connection:send('</div>')
  end

  connection:send('<input class="btn btn-info" type="submit" value="submit"></form></body></html>')
end
