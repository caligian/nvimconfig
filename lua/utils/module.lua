local function new_module(opts)
  validate {
    module_spec = {
      opts,
      {
        __allow_nonexistent = true,
        ["?__include"] = "module",
        ["?__freeze"] = "boolean",
      },
    },
  }

  local include = opts.__include
  local freeze = opts.__freeze
  local mt = {
    __constants = {},
    __type = "module",
    __name = name,
  }
  local mod = {}

  local is_constant = function(k)
    local cap = k:match "^[A-Z]"
    if cap then
      if #k == 1 or k:match "[A-Z0-9_]+$" then
        return true
      end
      return false
    end
    return false
  end

  local add_attribs = function(o)
    for key, val in pairs(o) do
      if not key:match "__include" and not key:match "__freeze" then
        if isa.f(val) then
          mod[key] = val
        elseif is_constant(key) then
          mt.__constants[key] = val
        else
          error(key .. " is not a constant or a method")
        end
      end
    end
  end

  local get_attrib = function(_, k)
    if mt.__constants[k] then
      return mt.__constants[k]
    end
    return mod[k]
  end

  local __newindex = function(_, key, val)
    if key:match "__type" or key:match "__name" or key:match "__constants" then
      error "Attempting to change main module properties"
    end

    if mt.__constants[key] then
      error(string.format("Attempting to change constant %s", key))
    end

    if isa.f(val) then
      mod[key] = val
    elseif is_constant(key) then
      mt.__constants[key] = val
    else
      error("Attempting to add non-method/non-constant " .. key)
    end
  end

  if include then
    add_attribs(mtget(include, "__constants"))
    add_attribs(include)
  end

  mt.__index = function(self, k)
    return get_attrib(self, k)
  end

  mt.__newindex = __newindex

  mod.get_type = function(_)
    return mt.__type
  end

  mod.include = function(other)
    validate { other_module = { other, "module" } }
    add_attribs(other)
    add_attribs(mtget(other, "__constants"))
  end

  mod.freeze = function()
    mt.__frozen = true
    mt.__newindex = function(_, _, _)
      error "Attempting to make changes to a frozen module"
    end
  end

  mod.unfreeze = function()
    mt.__frozen = false
    mt.__newindex = __newindex
  end

  if freeze then
    mod.freeze()
  end

  mt.__add = function(_, other)
    validate { other_module = { other, "module" } }

    return deepcopy(mod).include(other)
  end

  add_attribs(opts)
  setmetatable(mod, mt)

  return mod
end

function module(name)
  validate { module_name = { name, "string" } }

  if not name:match "^[A-Z]" then
    error "module_name should start with a capital letter"
  end

  if not name:match "[a-zA-Z0-9_]+" then
    error "module_name can only have alphanumeric characters"
  end

  return function(opts)
    local mod = new_module(opts)
    _G[name] = mod

    return mod
  end
end
