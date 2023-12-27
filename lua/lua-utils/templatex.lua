require "lua-utils.utils"

local lpeg = require "lpeg"
local P = lpeg.P
local Cb = lpeg.Cb
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

local parse = {}

function parse.keys(match, repl)
  local ks = C(P(lpeg.alnum) + (1 - P "."))
  local pat = Ct(ks * (P "." * ks) ^ 0)
  ks = pat:match(match)

  if not ks then
    return
  end

  local k = ks[1]
  repl = repl or {}

  if not repl[k] then
    error("undefined placeholder: " .. k)
  else
    assertisa(repl[k], "table")
  end

  local ok = dict.get(repl[k], list.sub(ks, 2, -1))
  if not ok then
    error("keys not found in table: " .. match)
  end

  return tostring(ok)
end

function parse.sed(match, repl)
  repl = repl or {}
  local _, till = match:find "/"
  local var = match:sub(1, till - 1)

  if not repl[var] then
    error("undefined placeholder: " .. var)
  else
    assertisa(repl[var], union("string", "number"))
  end

  local till_end = string.find(match, "[^\\]/", till + 1)

  if not till_end then
    error("expected spec {var/regex/replacement?}, got " .. match)
  end

  local regex = string.sub(match, till + 1, till_end)
  local with = string.sub(match, till_end + 2, #match)

  return (tostring(repl[var]):gsub(regex, with))
end

function parse.optional(match, repl)
  local var, default = match:match "^([^?]+)%?(.+)$"

  if not default then
    error("default key is undefined in " .. match)
  end

  local ok = repl[var] or repl[default]
  if not ok then
    if not default then
      error("undefined placeholder: " .. var)
    else
      error("undefined placeholder: " .. default)
    end
  end

  return ok
end

function parse.match(match, repl)
  repl = repl or {}
  local _, till = match:find "/"
  local var = match:sub(1, till - 1)

  if not repl[var] then
    error("undefined placeholder: " .. var)
  else
    assertisa(repl[var], union("string", "number"))
  end

  local regex = string.sub(match, till + 1, #match)
  if #regex == 0 then
    error("no regex defined for placeholder: " .. match)
  end

  local ok = repl[var]:match(regex) 
  if not ok then
    error("match failure for " .. match .. ' using ' .. regex)
  end

  return ok
end

function parse.parse(match, repl)
  local sed_open = match:find "[^\\]/"
  local sed_close = sed_open and match:find("[^\\]/", sed_open + 1)

  if sed_open and sed_close then
    return parse.sed(match, repl)
  elseif sed_open then
    return parse.match(match, repl)
  elseif match:match "%." then
    return parse.keys(match, repl)
  elseif match:match "%?" then
    return parse.optional(match, repl)
  else
    local ok = repl[match]
    if not ok then
      error("undefined placeholder: " .. match)
    end

    return ok
  end
end

local function gmatch(s, repl, crash)
  repl = repl or {}
  local open = P "{" - P "{{"
  local close = P "}" - P "}}"
  local placeholder = (open * Cs((lpeg.alnum + S "_.-/?") ^ 1) * close)
    / function(match)
      return parse.parse(match, repl)
    end

  local before = C(1 - placeholder) ^ 0
  local extra = C(1 - (before * placeholder))
  local pat = Ct((before * placeholder + extra) ^ 0) * P "\n" ^ 0
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

function F(x, opts, vars)
  local function use(_vars)
    opts = opts or {}
    local _assert = defined(opts.assert, true)
    return gmatch(x, _vars, _assert)
  end

  if not vars then
    return use
  end

  return use(vars)
end

local s = F "{a?b} {2} {3} {4/9}"
pp(s { za = 1, b = 2, bcd = 10000, ['2'] = 'hello', ['3'] = 'world', ['4'] = '/'  })

