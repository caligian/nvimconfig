local _class = require "pl.class"

function class(name, base)
  assert(type(name) == "string", 'name: string expected, got ' .. type(name))
  assert(name:match "^[A-Za-z0-9_]+$", "name: Should only contain alphanumeric characters")
  assert(string.sub(name, 1, 1):match "[A-Z]", "name: Should start with a capital letter")

  return _class[name](base)
end
