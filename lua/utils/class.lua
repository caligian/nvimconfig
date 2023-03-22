local _class = require "pl.class"

function class(name, base, force)
  assert(type(name) == "string", 'name: string expected, got ' .. type(name))
  assert(name:match "^[A-Za-z0-9_]+$", "name: Should only contain alphanumeric characters")
  assert(string.sub(name, 1, 1):match "[A-Z]", "name: Should start with a capital letter")

  if not _G[name] or force then
    return _class[name](base)
  end
end
