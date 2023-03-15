function string.split(s, delim)
  return vim.split(s, delim or " ")
end

function sprintf(fmt, ...)
  local args = { ... }

  for i = 1, #args do
    if is_a.t(args[i]) then
      args[i] = dump(args[i])
    end
  end

  return string.format(fmt, unpack(args))
end

function printf(...)
  print(sprintf(...))
end

function string.match_any(s, ...)
  for _, value in ipairs { ... } do
    local m = s:match(value)
    if m then
      return m
    end
  end
end
