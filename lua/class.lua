_class = require "pl.class"

class = function(name, base)
  return _class[name](base)
end

function new(name)
  return function(opts)
    opts = opts or {}
    local base = opts.base or opts.include
    local cls = class(name, base)

    for attrib, val in pairs(opts) do
      if attrib ~= "base" or attrib ~= "include" then
        cls[attrib] = val
      end
    end

    local mt = getmetatable(cls)
    local __call = mt.__call
    mt.__call = function(...)
      local instance = __call(...)
      local inst_mt = getmetatable(instance)
      inst_mt.__type = "class"

      return instance
    end

    return cls
  end
end
