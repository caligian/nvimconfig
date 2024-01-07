--- String utilities
require "lua-utils.utils"
require "lua-utils.table"

--- Extract substring
--- @param x string
--- @param from number supports negative indexes from -1
--- @param till? number supports negative indexes from -1
--- @return string|nil
function substr(x, from, till)
  local len = #x
  from = from or 1
  till = till or len
  from = from < 0 and len + (from + 1) or from
  till = till < 0 and len + (till + 1) or till

  if from > till or till > len or from < 0 then
    return
  end

  return x:sub(from, till)
end

--- Split from right. This will reverse the string before splitting so this will match everything (in sequence) in reverse
--- @overload fun(x: string, sep: string, maxtimes: number): string[]
function rsplit(x, sep, maxtimes, _prev, _n, _res)
  if #sep == 0 then
    local out = {}

    for i = 1, #x do
      list.append(out, { substr(x, i, i) })
    end

    return out
  end

  _res = _res or {}
  _prev = _prev or 1
  _n = _n or 0
  local res = _res
  local n = _n
  local prev = _prev

  if prev == 1 then
    x = reverse(x)
    --- @cast x string
  end

  if maxtimes and n > maxtimes or prev > #x then
    return reverse_liststr(res)
  end

  local a, b = string.find(x, sep, prev)
  if not a then
    list.append(res, { substr(x, prev, #x) })
    return res
  end

  list.append(res, { substr(x, prev, a - 1) })
  prev = b + 1

  return rsplit(x, sep, maxtimes, prev, n + 1, res)
end

--- Split string
--- @overload fun(x: string, sep: string, maxtimes: number): string[]
function split(x, sep, maxtimes, _prev, _n, _res)
  if #sep == 0 then
    local out = {}
    for i = 1, #x do
      list.append(out, { substr(x, i, i) })
    end

    return out
  end

  _res = _res or {}
  _prev = _prev or 1
  _n = _n or 1
  local res = _res
  local n = _n
  local prev = _prev

  if maxtimes and n > maxtimes then
    return res
  elseif prev > #x then
    return res
  end

  local a, b = string.find(x, sep, prev)
  if not a then
    res[#res + 1] = substr(x, prev, #x)
    return res
  end

  list.append(res, { substr(x, prev, a - 1) or "" })
  prev = b + 1

  return split(x, sep, maxtimes, prev, n + 1, res)
end

strsplit = split
strrsplit = rsplit

--- Matching multiple patterns
--- @param x string
--- @param ... string
--- @return string|nil
function strmatch(x, ...)
  local args = { ... }

  for i = 1, #args do
    local found = x:match(args[i])
    if found then
      return found
    end
  end
end

--- Get start and ending index of a matched pattern
--- @param x string
--- @param pattern string
--- @param init? number initial position (default: 1)
--- @param times? number number of times. -1 to get all matches (default: -1)
--- @return number[]|nil
function strfind(x, pattern, init, times)
  init = init or 1
  local a, b = init, 1
  local len = #x
  local res = {}
  local n = 0
  times = times or -1

  while a <= len do
    if times ~= -1 and n > times then
      break
    end

    a, b = x:find(pattern, a)

    if a then
      list.append(res, { { a, b } })
      a = b + 1
      n = n + 1
    else
      break
    end
  end

  if #res == 0 then
    return
  end

  return res
end

--- Check if string is ^[a-zA-Z_][0-9a-zA-Z_]*$
--- @param x string
--- @return string|nil
function is_identifier(x)
  return x:match "^[a-zA-Z_][0-9a-zA-Z_]*$"
end

--- Replace multiple patterns like sed
--- @param x string
--- @param subs list[] string.gsub arguments
--- @return string|nil
function sed(x, subs)
  local og = x

  for _, args in ipairs(subs) do
    x = x:gsub(unpack(args))
  end

  if og == x then
    return
  end

  return x
end

--- Remove excess whitespace from left and right ends
--- @param x string
--- @return string
function trim(x)
  return (x:gsub("^%s*", ""):gsub("%s*$", ""))
end

--- Remove excess whitespace from left
--- @param x string
--- @return string
function ltrim(x)
  return (x:gsub("^%s*", ""))
end

--- Remove excess whitespace from right
--- @param x string
--- @return string
function rtrim(x)
  return (x:gsub("%s*$", ""))
end

local function _chomp(x)
  if #x == 0 then
    return
  end

  local last = substr(x, -1, -1)

  if last == "\n" then
    return substr(x, 1, -2)
  end

  return x
end

--- Remove newlines from string or string[]
--- @param x string|string[]
--- @return string|string[]
function chomp(x)
  if #x == 0 then
    return x
  end

  if type(x) == "table" then
    local res = {}
    for i = 1, #x do
      res[#res + 1] = _chomp(x[i]) or x[i]
    end

    return res
  end

  return _chomp(x) or x
end

function startswith(x, s)
  return x:match("^" .. s)
end

function endswith(x, s)
  return x:match(s .. "$")
end

function gmatch(x, pat, times)
  times = times or -1
  local res = {}
  local i = 0

  for match in string.gmatch(x, pat) do
    if i > times then
      if #res == 0 then
        return
      end

      return res
    elseif i ~= -1 then
      i = i + 1
    end

    res[#res + 1] = match
  end

  if #res == 0 then
    return
  end

  return res
end
