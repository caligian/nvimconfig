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

function is_type(x) return mtget(x, "type") ~= nil end

function is_number(x) return type(x) == "number" end

function is_string(x) return type(x) == "string" end

function is_userdata(x) return type(x) == "userdata" end

function is_table(x) return type(x) == "table" end

function is_thread(x) return type(x) == "thread" end

function is_boolean(x) return type(x) == "boolean" end

function is_function(x) return type(x) == "function" end

function is_nil(x) return x == nil end

function is_error(x) return mtget(x, "type") == "error" end

function is_exception(x) return mtget(x, "type") == "exception" end

function is_class(x)
  if not is_table(x) then return false end

  local mt = mtget(x)
  if not mt then
    return false
  elseif mt.type == "class" then
    return x
  else
    return is_class(mt)
  end
end

function is_instance(x) return is_class(mtget(x)) end

function is_callable(x)
  if is_function(x) then return true end
  if not is_table(x) then return false end
  local mt = getmetatable(x) or {}
  return is_function(mt.__call)
end

function is_pure_table(x)
  return is_table(x)
      and not is_class(x)
      and not is_error(x)
      and not is_exception(x)
    or false
end

function is_seq(x)
  return is_table(x)
      and not is_class(x)
      and not is_error(x)
      and not is_exception(x)
    or false
end

function get_class(x) return is_class(x) end

function get_parent(x) return mtget(get_class(x), "parent") end

function get_type(x) return mtget(x, "type") end

function get_name(x)
  local cls = get_class(x)
  return cls and mtget(cls, "name") or mtget(x, "name")
end

function typeof(obj)
  if is_class(obj) then
    return "class"
  elseif is_type(obj) then
    return get_type(obj)
  elseif is_callable(obj) then
    return "callable"
  else
    return type(obj)
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

--------------------------------------------------
require "utils.funcs"
require "utils.debug"
require "utils.string"
require "utils.aliased"
require "utils.table"
require "utils.errors"
require "utils.Class"
require "utils.Set"
require "utils.types"
require "utils.nvim"
require "utils.misc"
require "utils.telescope"
require "utils.color"

--------------------------------------------------
require "utils.Autocmd"
require "utils.Keybinding"
require "utils.Buffer"
require "utils.Term"
require "utils.Process"
