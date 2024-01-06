require 'lua-utils.utils'

local assertx = module()

function assertx.table(x, y, deep_match)
  local x_type, y_type = type(x), type(y)

  assert(x_type == 'table', 'expected table, got ' .. x_type)
  assert(y_type == 'table', 'expected table, got ' .. y_type)

  local x_len = size(x)
  local y_len = size(y)

  if x_len ~= y_len then
    return 
      false, 
      "expected table of equal sizes, got " .. string.format("%d and %d", x_len, y_len)
  end

  if not deep_match then
    for i, v in pairs(x) do
      if y[i] ~= v then
        error(i .. ': nonequal elements found ')
      end
    end

    return true
  end

  local queue = {}
  local X = x
  local Y = y
  local current_prefix = ''

  while true do
    for i, v in pairs(X) do
      local y_v = Y[i]

      if y_v == nil then
        error(current_prefix .. i .. ': element missing in Y')
      elseif type(y_v) ~= type(v) then
        error(current_prefix .. i .. ': unequal types')
      elseif type(v) == 'table' then
        queue[#queue+1] = i
      elseif v ~= y_v then
        error(current_prefix .. i .. ': nonequal elements found ')
      end
    end

    local next_i = queue[#queue]
    if next_i then
      queue[#queue] = nil
      X = X[next_i]
      Y = Y[next_i]
      current_prefix = tostring(next_i) .. '.'
    else
      return true
    end
  end
end

function assertx.list(x, y, deep_match)
  local x_type, y_type = type(x), type(y)

  assert(x_type == 'table', 'expected table, got ' .. x_type)
  assert(y_type == 'table', 'expected table, got ' .. y_type)

  local x_len = #x
  local y_len = #y

  if #x ~= #y then
    return 
      false, 
      "expected lists of equal length, got sizes " .. string.format("%d and %d", x_len, y_len)
  end

  if not deep_match then
    for i=1, #y do
      if y[i] ~= x[i] then
        error(i .. ': nonequal elements found ')
      end
    end

    return true
  end

  local queue = {}
  local X = x
  local Y = y
  local current_prefix = ''

  while true do
    for i=1, #X do
      local v = X[i]
      local y_v = Y[i]

      if y_v == nil then
        error(current_prefix .. i .. ': element missing in Y')
      elseif type(y_v) ~= type(v) then
        error(current_prefix .. i .. ': unequal types')
      elseif type(v) == 'table' then
        queue[#queue+1] = i
      elseif v ~= y_v then
        error(current_prefix .. i .. ': nonequal elements found ')
      end
    end

    local next_i = queue[#queue]
    if next_i then
      queue[#queue] = nil
      X = X[next_i]
      Y = Y[next_i]
      current_prefix = tostring(next_i) .. '.'
    else
      return true
    end
  end
end

function assertx:__call(bool_test, msg)
  if not bool_test then
    error(msg)
  end
end

function assertx.type(x, y)
  assert(type(x) == type(y), 'expected equal types, got ' .. type(x) .. ' and ' .. type(y))

  local x_mt = getmetatable(x)
  local y_mt = getmetatable(y)

  if not x_mt and not y_mt then
    return true
  elseif not x_mt then
    error('missing metatable in X')
  elseif not y_mt then
    error('missing metatable in Y')
  elseif not x_mt.type then
    error('X is not a type')
  elseif not y_mt.type then
    error('Y is not a type')
  elseif x_mt.type ~= y_mt.type then
    error('expected type ' .. y_mt.type .. ', got ' .. x_mt.type)
  end

  return true
end

assertx.isa = assertisa

return assertx
