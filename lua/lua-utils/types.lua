--- Type checking utilities
-- Lua has 7 (excluding nil) distinct types. We add 'class' and 'callable' to that list. 
-- Tables and classes will be distinguished and treated accordingly similar to Ruby, Python, etc
-- However these types will be accessible only via .typeof
-- @module types
local types = {}
local utils = require "lua-utils.utils"

--- Lua builtin types
-- @table types.builtin
types.builtin = {
  userdata = true,
  number = true,
  string = true,
  table = true,
  thread = true,
  ["function"] = true,
  callable = true,
  class = true,
  boolean = true,
}

--- Is x a number?
-- @param x any
-- @return boolean
function types.is_number(x) return type(x) == "number" end

--- Is x a string?
-- @param x any
-- @return boolean
function types.is_string(x) return type(x) == "string" end

--- Is x a userdata?
-- @param x any
-- @return boolean
function types.is_userdata(x) return type(x) == "userdata" end

--- Is x a coroutine?
-- @param x any
-- @return boolean
function types.is_thread(x) return type(x) == "thread" end

--- Is x a boolean?
-- @param x any
-- @return boolean
function types.is_boolean(x) return type(x) == "boolean" end

--- Is x a function?
-- @param x any
-- @return boolean
function types.is_function(x) return type(x) == "function" end

--- Is x nil
-- @param x any
-- @return boolean
function types.is_nil(x) return x == nil end

--- Is x a class?
-- @return boolean
function types.is_class(x)
  if type(x) ~= "table" then return false end

  local mt = utils.mtget(x)
  if not mt then
    return false
  elseif mt.type == "class" then
    return x
  else
    return types.is_class(mt)
  end
end

--- Is x a table (array|dict)?
-- @param x any
-- @return boolean
function types.is_table(x) return type(x) == "table" and not types.is_class(x) end

--- Is x a class instance?
-- @param x any
-- @return boolean
function types.is_instance(x) return types.is_class(utils.mtget(x)) end

--- Is x a callable (table with __call metamethod or function)?
-- @param x any
-- @return boolean
function types.is_callable(x)
  if types.is_function(x) then return true end
  if not types.is_table(x) then return false end
  local mt = getmetatable(x) or {}
  return types.is_function(mt.__call)
end

--- Get type name of a table
-- @param x any
-- @return ?string
function types.get_type(x)
  if types.is_class(x) then
    return "class"
  elseif types.is_table(x) then
    if types.is_callable(x) then
      return "callable"
    else
      return "table"
    end
  elseif types.is_function(x) then
    return "callable"
  else
    return type(x)
  end
end

--- Get type name of a table
-- @param x any
-- @return ?string
function types.typeof(x) return types.get_type(x) end

--- Is x a class?
-- @param x class
-- @return ?class
function types.get_class(x)
  if types.is_instance(x) then
    return utils.mtget(x)
  elseif types.is_class(x) then
    return x
  end
end

-- Get object name
-- @param x any
-- @return ?string
function types.get_name(x)
  local cls = types.get_class(x)
  return cls and utils.mtget(cls, "name")
end

return types
