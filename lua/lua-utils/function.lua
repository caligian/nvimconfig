--- Decorate a function
--- @param f1 function to be decorated
--- @param f2 function decorating function
--- @return function
function decorate(f1, f2)
  return function(...)
    return f2(f1(...))
  end
end

--- Apply an list of args to a function
--- @param f function
--- @param args list to apply
--- @return any
function apply(f, args)
  return f(unpack(args))
end

--- Prepend args and apply params
--- @param f function
--- @param ... any params to prepend
--- @return function
function partial(f, ...)
  local outer = { ... }

  return function(...)
    local inner = { ... }
    local len = #outer

    for i=1, len do
      inner[#inner+1] = outer[i]
    end

    return f(unpack(inner))
  end
end

--- Append args and apply params
--- @param f function
--- @param ... any params to append
--- @return function
function rpartial(f, ...)
  local outer = { ... }

  return function(...)
    local inner = { ... }

    for i=1, #inner do
      outer[#outer+1] = inner[i]
    end

    return f(unpack(outer))
  end
end

--- Return object as is
--- @param x any
--- @return any
function identity(x)
  return x
end

--- Pass an element through N functions
--- @param x any
--- @param ... fn[]
--- @return any
function thread(x, ...)
  local out = x
  local args = { ... }

  for i = 1, #args do
    local f = args[i]
    out = f(out)
  end

  return out
end
