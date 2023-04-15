-- @table V table containing this framework configuration and other goodies
V = V or {}

-- @field global Tracks the global variables made by V
global = global or {}

function mtget(obj, k)
  if type(obj) ~= "table" then return end
  local mt = getmetatable(obj)
  if not mt then return end
  if k then return mt[k] end
  return mt
end

function mtset(obj, k, v)
  if type(obj) ~= "table" then return end
  local mt = getmetatable(obj)
  if not mt then return end
  if k and v then
    mt[k] = v
    return v
  end
end

function is_number(x) return type(x) == "number" end
function is_string(x) return type(x) == "string" end
function is_userdata(x) return type(x) == "userdata" end
function is_table(x) return type(x) == "table" end
function is_thread(x) return type(x) == "thread" end
function is_boolean(x) return type(x) == "boolean" end
function is_function(x) return type(x) == "function" end
function is_nil(x) return x == nil end

function is_error(x)
  return mtget(x, 'type') == 'error'
end

function is_exception(x)
  return mtget(x, 'type') == 'exception'
end

function is_class(obj)
  if not is_table(obj) then return false end

  local mt = mtget(obj)
  if not mt then
    return false
  elseif mt.type == "class" then
    return true
  else
    return mtget(mt, "type") == "class"
  end

  return false
end

function is_type(x) return mtget(x, "type") ~= nil end

function get_type(x) return mtget(x, "type") end

function is_callable(x)
  if is_function(x) then return true end
  if not is_table(x) then return false end
  local mt = getmetatable(x) or {}
  return is_function(mt.__call)
end

function is_pure_table(x)
  if type(x) == "table" and not is_class(x) then return true end
  return false
end

function is_seq(x)
  if not is_table(x) then
    return false
  elseif is_class(x) then
    return false
  end
  return true
end

function is_instance(x)
  if not is_table(x) then
    return false
  elseif is_class(mtget(x)) then
    return true
  end
  return false
end

function typeof(obj)
  if is_class(obj) then
    return "class"
  elseif is_type(obj) then
    return get_type(obj)
  elseif is_callable(obj) then
    return "callable"
  elseif is_table(obj) then
    return "table"
  else
    return type(obj)
  end
end

function get_class(x)
  if not is_class(x) then
    return false
  elseif is_instance(x) then
    return mtget(x)
  else
    return x
  end
end

function get_name(x)
  if is_class(x) then return mtget(get_class(x), "name") end
  return mtget(x, "name")
end

function get_parent(x)
  if not is_class(x) then return false end

  if is_instance(x) then
    return mtget(get_class(x), "parent")
  else
    return mtget(x, "parent")
  end
end

function copy(obj, deep)
  if not is_table(obj) then
    return obj
  elseif deep then
    return vim.deepcopy(obj)
  end

  local out = {}
  for key, value in pairs(obj) do
    out[key] = value
  end
  return out
end

--
require "utils.funcs"
require "utils.debug"
require "utils.string"
require "utils.aliased"
require "utils.table"
require 'utils.errors'
require "utils.Class"
require "utils.Set"
require "utils.types"
require "utils.nvim"
require "utils.misc"
require "utils.telescope"
require "utils.color"

-- classes
require "utils.Autocmd"
require "utils.Keybinding"
require "utils.Buffer"
require "utils.Term"
require "utils.Process"
