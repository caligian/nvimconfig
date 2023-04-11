-- @table V table containing this framework configuration and other goodies
V = V or {}

-- @field global Tracks the global variables made by V
global = global or {}

function mtget(obj, k)
	if type(obj) ~= "table" then
		return
	end
	local mt = getmetatable(obj)
	if not mt then
		return
	end
	if k then
		return mt[k], mt
	end
	return mt
end

function mtset(obj, k, v)
	if type(obj) ~= "table" then
		return
	end
	local mt = getmetatable(obj)
	if not mt then
		return
	end
	if k and v then
		mt[k] = v
		return v, mt
	end
end

function is_number(x)
	return type(x) == "number"
end
function is_string(x)
	return type(x) == "string"
end
function is_userdata(x)
	return type(x) == "userdata"
end
function is_table(x)
	return type(x) == "table"
end
function is_thread(x)
	return type(x) == "thread"
end
function is_boolean(x)
	return type(x) == "boolean"
end
function is_function(x)
	return type(x) == "function"
end
function is_nil(x)
	return x == nil
end
function is_class(obj)
	return mtget(obj, "type") == "class"
end

function is_callable(x)
	if is_function(x) then
		return true
	end
	if not is_table(x) then
		return false
	end
	local mt = getmetatable(x) or {}
	return is_function(mt.__call)
end

function is_pure_table(x)
	if type(x) == "table" and not is_class(x) then
		return true
	end
	return false
end

function typeof(obj)
	if is_class(obj) then
		return "class"
	elseif is_callable(obj) then
		return "callable"
	elseif is_table(obj) then
		return "table"
	else
		return type(obj)
	end
end

function get_class(cls)
	if is_instance(cls) then
		return mtget(cls, "class")
	elseif is_class(cls) then
		return cls
	end
	return false
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
require("utils.funcs")
require("utils.debug")
require("utils.aliased")
require("utils.table")
require("utils.Class")
require("utils.Set")
require("utils.Class")
require("utils.types")
require("utils.string")
require("utils.nvim")
require("utils.misc")
require("utils.telescope")
require("utils.color")

-- classes
require("utils.Autocmd")
require("utils.Keybinding")
require("utils.Buffer")
require("utils.Term")
require("utils.Process")
