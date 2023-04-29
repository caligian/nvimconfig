--- Common function operations
-- @module fn
local fn = {}

--- Decorate a function
-- @param f1 function to be decorated
-- @param f2 decorater function
-- @return function
function fn.decorate(f1, f2)
  return function(...) return f2(f1(...)) end
end

--- Apply an array of args to a function
-- @param f callable
-- @param args params to apply
-- @return any
function fn.apply(f, args) return f(unpack(args)) end

--- Prepend args and apply params
-- @param f callable
-- @param ... params to prepend
-- @return any
function fn.rpartial(f, ...)
  local outer = { ... }
  return function(...)
    local inner = { ... }
    local len = #outer
    for idx, a in ipairs(outer) do
      inner[len + idx] = a
    end

    return f(unpack(inner))
  end
end

--- Append args and apply params
-- @param f callable
-- @param ... params to append
-- @return any
function fn.partial(f, ...)
  local outer = { ... }
  return function(...)
    local inner = { ... }
    local len = #outer
    for idx, a in ipairs(inner) do
      outer[len + idx] = a
    end

    return f(unpack(outer))
  end
end

--- Return object
-- @param x any
-- @return x
function fn.identity(x) return x end

--- Pass an element through N callables
-- @param x any
-- @param ... callables
-- @return  any
function fn.thread(x, ...)
  local out = x
  local args = { ... }

  for i = 1, #args do
    local f = args[i]
    out = f(out)
  end

  return out
end

return fn
