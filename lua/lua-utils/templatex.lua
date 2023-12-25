require 'lua-utils'

local lpeg = require "lpeg"
local P = lpeg.P
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

local a = [[echo {helloworldmotherfucker} {2};{2};{3} {4} {5} {{5}} {6} {7}
{8}
{9} {10} {11} {23}
{{24}} {99}
{{333}}
{2} ajsdlf;skdjf {adjadkf}
]]

local function gmatch(s, init, repl)
  repl = repl or {}
  local open = P"{" - P "{{"
  local close = P"}" - P "}}"
  local placeholder = open * C(lpeg.alnum ^ 1) * close
  local before = P(1 - placeholder) ^ 0
  local pat = before * placeholder
  local pat = Ct(before * placeholder * (before * placeholder) ^ 0 * P"\n" ^ 0)
  local var = pat:match(s)

  return var
end

pp(gmatch(a, 1))
