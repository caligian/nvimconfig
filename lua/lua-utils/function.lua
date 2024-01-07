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
--- @param ... list params to prepend
--- @return function
function rpartial(f, ...)
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
--- @param f function
--- @param ... list params to append
--- @return function
function partial(f, ...)
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

function is_class(self)
  local mt = mtget(self)
  if mt.type and mt.class then
    return true
  end

  return false
end

function is_classmod(self)
  return is_table(self) and mtget(self, "type") == "classmod" and self or false
end

function is_instance(self, other)
  if not is_table(self) or not is_table(other) then
    return false
  elseif is_classmod(other) or is_class(other) then
    return false
  elseif is_classmod(self) or is_class(self) then
    return false
  else
    return self.modname() == other.modname()
  end
end
