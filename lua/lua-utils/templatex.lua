require "lua-utils.utils"

local lpeg = require "lpeg"
local P = lpeg.P
local Cg = lpeg.Cg
local S = lpeg.S
local R = lpeg.R
local C = lpeg.C
local Ct = lpeg.Ct
local Cp = lpeg.Cp()
local Cs = lpeg.Cs
local V = lpeg.V

lpeg.locale(lpeg)

--[[
f strings like in python. However they cannot execute arbitrary code

echo {1} {2} {3}
echo {path}
sed -i '{sed_pat}' {fname}

Add {} around the parenthesis to ignore it
echo {{1}} -- will print echo {1}

--]]

local a = [[{helloworldmotherfucker} {2};{2};{3} {4} {5} {{5}} {6} {7}
{8}
{9} {10} {11} {23}
{{24}} {99}
{{333}}
{2} ajsdlf;skdjf {adjadkf}
]]

local function sub_table(repl, crash)
  return setmetatable(repl, {
    __index = function(_, key)
      if crash then
        error("undefined placeholder: " .. key)
      end

      return key
    end,
  })
end

local function gmatch(s, repl, crash)
  repl = sub_table(repl or {}, crash)
  local open = P "{" - P "{{"
  local close = P "}" - P "}}"
  local placeholder = (open * Cs((lpeg.alnum + S "_-/") ^ 1) * close) / repl
  local before = C(1 - placeholder)
  local extra = C(1 - (before * placeholder))
  local pat = Ct((before * placeholder + extra) ^ 0 * P "\n" ^ 0)
  local var = pat:match(s)

  if var then
    for i = 1, #var - 1 do
      local current, next = var[i], var[i + 1]
      if (current == "{" and next == "{") or (current == "}" and next == "}") then
        var[i] = ""
      end
    end

    return join(var, "")
  else
    return s
  end
end

function F(x, vars)
  local function use(_vars)
    local crash = _vars.__assert
    return gmatch(x, _vars, crash)
  end

  if not vars then
    return use
  end

  return use(vars)
end
