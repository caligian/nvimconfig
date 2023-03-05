_class = require("pl.class")

function new(name)
  return function(opts)
    local base = opts.base
    local cls = _class[name](base)
    local initialize = opts.initialize

    cls._init = function(self, ...)
      if opts.initialize then
        opts.initialize(self, ...)
      end

      return self
    end

    opts.initialize = nil
    opts.base = nil

    for attrib, val in pairs(opts) do
      cls[attrib] = val
    end

    return cls
  end
end
