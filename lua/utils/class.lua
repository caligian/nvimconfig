local _class = require "pl.class"

function class(name, base)
  validate {
    class_name = { "string", name },
    ["?base"] = { "class", base },
  }
  return _class[name](base)
end
