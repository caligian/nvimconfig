require "lua-utils.table"
require "lua-utils.string"

local function varsx(x)
  local out = {}

  for var in string.gmatch(x, ".?[{][0-9a-zA-Z_.-]+[}].?") do
    local open = var:find "[{]"
    local open1 = var:find("[{]", open + 1)
    local close = var:find "[}]"
    local close1 = var:find("[}]", close + 1)

    if not close1 and not open1 then
      var = var:sub(open + 1, close - 1)
      out[var] = { open, close }
      list.append(out, var)
    else
    end
  end

  return out
end

local function sub(x, var, repl)
  if istable(var) then
    var, repl = unpack(var)
  end

  x = x:gsub("%{" .. var .. "%}", repl)
  return x
end

local function subx(x, repl, opts)
  opts = opts or {}
  local vars = varsx(x)
  local msg = {}
  local ignore = opts.ignore
  local _assert = opts.assert

  for key, value in pairs(repl) do
    local name = tostring(key)
    local var = vars[name]
    local open, close

    if not var then
      if _assert then
        error(
          "expected placeholder for " .. name .. ", got nil"
        )
      end

      msg[key] = true
    else
      open, close = unpack(var)

      -- check start and end and replace accordingly
      x = sub(x, name, value)
    end
  end

  x = x:gsub('%{%{([^}]*)%}%}', '{%1}')

  if size(msg) > 0 and not ignore then
    return nil, msg
  end

  return x
end

--- Return a template function.
--- @param x string
--- @return (fun(vars:dict|list[]): string?, string[]?) result failure without `ignore = true` in vars will `return nil, string[]`
function template(x)
  return function (vars, opts)
    pp(vars)
    return subx(x, vars, opts)
  end
end

function istemplate(var)
  if not isstring(var) then
    return false
  end

  local open = var:find "[{]"
  if not open then
    return false
  end

  local open1 = var:find("[{]", open + 1)
  local close = var:find "[}]"
  local close1 = var:find("[}]", close + 1)

  return (not close1 or not open1)
end
