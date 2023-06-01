function imageof(x, y)
  local img = mtget(x, 'image')
  if not img then return end
  return img.of == y
end

function image(x, y, opts)
  local check = is { "table", "class", "callable" }
  validate {
    table1 = { check, x },
    table2 = { check, y },
  }

  local x_mt = mtget(x) or {}
  assert(not x_mt.image, 'x is already mirroring another table')

  opts = opts or {}
  local y_mt = mtget(y) or {}
  local y_newindex = y_mt.__newindex
  y_mt.__oldnewindex =  y_newindex
  x_mt.image = dict.merge({ of = y }, opts)
  local include, exclude

  if opts.exclude then
    exclude = array.todict(array.toarray(opts.exclude))
  elseif opts.include then
    include = array.todict(array.toarray(opts.include))
  end

  local function __newindex(self, key, value)
    rawset(self, key, value)

    local test = (not include and not exclude)
      or (exclude and not exclude[key])
      or (include and include[key])

    if test then
      rawset(x, key, value)
    end

    return value
  end

  function y_mt:__newindex(key, value)
    if y_newindex then y_newindex(self, key, value) end
    return __newindex(self, key, value)
  end

  mtset(y, y_mt)

  return x
end

function disableimage(x)
  local mt_x = mtget(x)
  if not mt_x then return end

  local current = mt_x.__newindex
  mt_x.__newindex = mt_x.__oldnewindex

  return current
end
