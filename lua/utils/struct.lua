require "utils._utils"

--[[
Naming conventions
metamethods: ^__
private-methods: ^_
methods: any
vars: any
constants: [A-Z][A-Z0-9]+
--]]

local function new_struct(opts)
  validate {
    struct_spec = {
      opts,
      {
        __allow_nonexistent = true,
        ["?__freeze"] = "boolean",
        ["?__include"] = function(x)
          return isa.m or isa.r(x)
        end,
      },
    },
  }

  local include = opts.__include
  local freeze = opts.__freeze
  local mt = {
    __frozen = false,
    __methods = {},
    __common = {},
    __vars = {},
    __constants = {},
    __type = "struct",
    __name = name,
  }

  return function(...)
    local self = {}
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
            if key:match "^__" then
              mt[key] = val
            else
              mt.__methods[key] = val
            end
          elseif is_constant(key) then
            mt.__constants[key] = val
          else
            mt.__vars[key] = val
          end
        end
      end
    end

    local get_attrib = function(_, k)
      if mt.__vars[k] then
        return mt.__vars[k]
      elseif mt.__constants[k] then
        return mt.__constants[k]
      elseif mt.__common[k] then
        return mt.__common[k]
      end
      return mt.__methods[k]
    end

    local __newindex = function(self, key, val)
      if
        key:match "__type"
        or key:match "__name"
        or key:match "__methods"
        or key:match "__vars"
        or key:match "__constants"
      then
        error "Attempting to change main struct properties"
      end

      if mt.__constants[key] then
        error(string.format("Attempting to change constant %s", key))
      end

      if isa.f(val) then
        mt.__methods[key] = val
      elseif is_constant(key) then
        mt.__constants[key] = val
      else
        mt.__vars[key] = val
      end
    end

    mt.__index = function(self, k)
      return get_attrib(self, k)
    end

    mt.__newindex = __newindex

    local common = mt.__common
    common.get_type = function(_)
      return mt.__type
    end

    common.freeze = function(_)
      mt.__frozen = true
      mt.__newindex = function(_, _, _)
        error "Attempting to make changes to a frozen struct"
      end
    end

    common.unfreeze = function(_)
      mt.__frozen = false
      mt.__newindex = __newindex
    end

    -- Metacommon will be skipped
    common.include = function(_, other)
      validate {
        module_or_struct = {
          other,
          function(x)
            return (isa.m(x) or isa.r(x))
          end,
        },
      }

      local other_mt = getmetatable(other) or {}
      if isa.m(include) then
        add_attribs(other_mt.__constants)
      else
        add_attribs(other_mt.__vars)
        add_attribs(other_mt.__common)
        add_attribs(other_mt.__constants)
      end
    end

    setmetatable(self, mt)
    add_attribs(opts)

    if include then
      self:include(include)
    end

    if freeze then
      self:freeze()
    end

    local init = mt.__methods.init
    if init then
      init(self, ...)
    end
    return self
  end
end

function struct(name)
  validate { struct_name = { name, "string" } }

  if not name:match "^[A-Z]" then
    error "struct_name should start with a capital letter"
  end

  if not name:match "[a-zA-Z0-9_]+" then
    error "struct_name can only have alphanumeric characters"
  end

  return function(opts)
    local s = new_struct(opts)
    _G[name] = s

    return s
  end
end
