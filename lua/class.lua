_class = require("pl.class")

class = function(name, base)
	return _class[name](base)
end

function new(name)
    return function(opts)
        opts = opts or {}
    local base = opts.base
    local cls = class(name, base)
    opts.initialize = nil
    opts.base = nil

    for attrib, val in pairs(opts) do
      cls[attrib] = val
    end

    return cls
  end
end
