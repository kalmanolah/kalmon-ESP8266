math = {}
math.pi = 3141593 / 1000000

math.abs = function(v)
  return v < 0 and v * -1 or v
end

math.fmod = function(x, y)
  return x % y
end

math.correct_radians = function(v)
  while v > math.pi * 2 do
    v = v - math.pi * 2
  end

  while v < - math.pi * 2 do
    v = v + math.pi * 2
  end

  return v
end

math.pow = function(b, p)
  local e = b

  if (p == 0) then
    return 1
  end

  if (p < 0) then
    p = p * (-1)
  end

  for c = p, 2, -1 do
    e = e * b
  end

  return e
end

math.fact = function(b)
  if (b == 1) or (b == 0) then
    return 1
  end

  local e = 1

  for c = b, 1, -1 do
    e = e * c
  end

  return e
end

math.cos = function(b, p)
  local e = 1
  b = math.correct_radians(b)
  p = p or 10

  for i = 1, p do
    e = e + (math.pow(-1, i) * math.pow(b, 2 * i) / math.fact(2 * i))
  end

  return e
end
