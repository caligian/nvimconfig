require "lua-utils.table"
require "lua-utils.string"

local function get_vars(x)
  local out = {}
  local new_x = x

  for var in string.gmatch(x, ".?[{][0-9a-zA-Z_.-]+[}].?") do
    local open = var:find "[{]"
    local open1 = var:find("[{]", open + 1)
    local close = var:find "[}]"
    local close1 = var:find("[}]", close + 1)

    if not close1 or not open1 then
      var = var:sub(open + 1, close - 1)
      out[var] = true
      list.append(out, var)
    else
      new_x = new_x:gsub("[{][{]([^}]+)[}][}]", "{%1}")
    end
  end

  return new_x, out
end

local function sub(x, var, repl)
  if istable(var) then
    var, repl = unpack(var)
  end

  x = x:gsub("%{" .. var .. "%}", repl)
  return x
end

local function sub_vars(x, repl)
  local vars
  x, vars = get_vars(x)
  local msg = {}
  local ignore = repl.ignore
  local _assert = repl.assert

  for key, value in pairs(repl) do
    if key ~= "assert" and key ~= "ignore" then
      local name = tostring(key)

      if not vars[name] then
        if _assert then
          error(
            "expected placeholder for "
              .. name
              .. ", got nil"
          )
        end
        msg[#msg + 1] = name
      else
        x = sub(x, name, value)
      end
    end
  end

  if #msg > 0 and not ignore then
    return nil, msg
  end

  return x, msg
end

--- Return a template function.
--- @param x string
--- @return (fun(vars:dict|list[]): string?, string[]?) result failure without `ignore = true` in vars will `return nil, string[]`
function template(x)
  local function do_replace(_vars)
    return sub_vars(x, _vars)
  end

  return do_replace
end

function istemplate(var)
  local open = var:find "[{]"
  if not open then
    return false
  end

  local open1 = var:find("[{]", open + 1)
  local close = var:find "[}]"
  local close1 = var:find("[}]", close + 1)

  return (not close1 or not open1)
end
