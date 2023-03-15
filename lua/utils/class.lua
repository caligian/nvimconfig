local _class = require "pl.class"

local function param_error_s(name, expected, got)
  return string.format("%s: expected %s got %s", name, tostring(expected), tostring(got))
end

function class(name, base)
  assert(type(name) == "string", param_error_s("name", "string", name))
  assert(name:match "^[A-Za-z0-9_]+$", "name: Should only contain alphanumeric characters")
  assert(string.sub(name, 1, 1):match "[A-Z]", "name: Should start with a capital letter")

  return _class[name](base)
end
