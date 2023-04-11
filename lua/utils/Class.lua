require("utils.table")

Class = {}
local Mt = {}
setmetatable(Class, Mt)

local valid_mt_ks = {
	__eq = true,
	__ne = true,
	__ge = true,
	__gt = true,
	__le = true,
	__lt = true,
	__add = true,
	__sub = true,
	__mul = true,
	__div = true,
	__mod = true,
	__pow = true,
	__tostring = true,
	__tonumber = true,
	__index = true,
	__newindex = true,
	__call = true,
	__metatable = true,
	__mode = true,
}

local function assert_is_class(cls)
	assert(is_class(cls), "expected class, got " .. tostring(cls))
end

local comparators = {
	eq = function(self, other)
		assert_is_class(other)

		local vars = get_vars(other)
		local self_vars = get_vars(self)

		for key, value in pairs(self_vars) do
			local self_value = self[key]
			local ok
			if not self_value then
				ok = false
			elseif not is_class(value) and is_table(value) then
				if is_class(self_value) or not is_table(self_value) then
					ok = false
				else
					ok = select(2, table.compare(self_value, value))
				end
			else
				ok = self[key] == value
			end

			if not ok then
				return false
			end
		end

		return true
	end,

	equal = function(self, other)
		assert_is_class(other)

		local vars = get_vars(other)
		local self_vars = get_vars(self)
		local ok

		for key, value in pairs(self_vars) do
			if not self[key] then
				ok = false
			else
				ok = self[key] == value
			end

			if not ok then
				return false
			end
		end

		return true
	end,

	name = function(self, other)
		return get_name(self) == get_name(other)
	end,
}

comparators.not_equal = function(self, other)
	return comparators.equal(self, other)
end
comparators.not_eq = function(self, other)
	return comparators.eq(self, other)
end
comparators.not_name = function(self, other)
	return comparators.name(self, other)
end

function is_instance(inst)
	return is_class(inst) and mtget(inst, "instance")
end

function is_instance_of(inst, cls)
	return is_instance(inst) and get_class(inst) == get_class(cls) or false
end

function get_parent(cls)
	if is_instance(cls) or is_class(cls) then
		return mtget(cls, "parent")
	end
	return false
end

function get_ancestors(cls)
	cls = get_class(cls)
	local ancestors = {}
	local ancestor = get_parent(cls)
	if not ancestor then
		return
	end
	ancestors[1] = ancestor
	local i = 2

	while ancestor do
		ancestor = get_parent(ancestor)
		if ancestor then
			ancestors[i] = ancestor
			i = i + 1
		end
	end

	return ancestors
end

function is_parent_of(cls, inst)
	return is_class(inst) and cls == get_parent(inst) or false
end

function is_ancestor_of(x, y)
	if not is_class(x) or not is_class(y) then
		return false
	end

	local parent = x
	local child_parent = get_parent(y)
	if parent == child_parent then
		return true
	end

	while parent do
		parent = get_parent(parent)
		if parent == child_parent then
			return true
		end
	end

	return false
end

function is_callable(f)
	return type(f) == "function" or mtget(f, "__call")
end

function get_vars(obj)
	local out = {}
	for key, value in pairs(obj) do
		if not is_callable(value) then
			out[key] = value
		end
	end
	return out
end

function get_methods(obj)
	local out = {}
	for key, value in pairs(obj) do
		if is_callable(value) then
			out[key] = value
		end
	end
	return out
end

function get_method(obj, k)
	local methods = get_methods(obj)
	if not methods then
		return
	end
	return methods[k]
end

function get_var(obj, k)
	local vars = get_vars(obj)
	if not vars then
		return
	end
	return vars[k]
end

function get_attrib(obj, k)
	return obj[k]
end

function get_attribs(obj)
	local out = {}
	for key, value in pairs(obj) do
		out[key] = value
	end
	return out
end

function include(obj, t, use_attrib, ignore_methods)
	for key, value in pairs(t) do
		if is_callable(value) then
			if valid_mt_ks[key] and key ~= "__newindex" and key ~= "__index" then
				obj[key] = value
			elseif not ignore_methods then
				obj[key] = function(inst, ...)
					if inst and is_class(inst) then
						return value(inst[use_attrib] or inst, ...)
					else
						return value(inst, ...)
					end
				end
			end
		else
			obj[key] = value
		end
	end
	return obj
end

function is_child_of(child, parent)
	return get_parent(child) == get_class(parent)
end

function get_name(obj)
	return is_class(obj) and mtget(obj, "name")
end

local function super(obj)
	local parent = get_parent(obj)
	if parent and parent.init then
		return parent.init
	end
	return function(...)
		return ...
	end
end

local function is_a(x, y)
	if x == y then
		return true
	end
	if not is_class(x) then
		return false
	end
	if not is_class(y) then
		return false
	end

	return get_class(x) == get_class(y) or is_ancestor_of(y, x) or false
end

Class.is_class = is_class
Class.is_instance_of = is_instance_of
Class.is_instance = is_instance
Class.get_class = get_class
Class.is_ancestor_of = is_ancestor_of
Class.get_parent = get_parent
Class.is_parent_of = is_parent_of
Class.get_vars = get_vars
Class.get_methods = get_methods
Class.get_method = get_method
Class.get_var = get_var
Class.get_attribs = get_attribs
Class.get_attrib = get_attrib
Class.include = include
Class.is_child_of = is_child_of
Class.get_name = get_name
Class.super = super
Class.is_a = is_a
Class.get_ancestors = get_ancestors

local function create_instance(cls, opts, ...)
	if cls then
		assert(is_class(cls), "class expected, got " .. type(cls))
	end

	opts = opts or {}
	local obj = { class = cls }
	local mt = {}

	if opts.include then
		assert(is_table(opts.include), "table expected, got " .. tostring(opts.include))
		if opts.struct then
			include(obj, opts.include, nil, true)
		else
			include(obj, opts.include, opts.include_using_attrib)
		end
	elseif opts.struct then
		include(obj, cls, nil, true)
	elseif opts.include_using_attrib then
		include(obj, cls, opts.include_using_attrib)
	else
		include(obj, cls)
	end

	for key, value in pairs(mtget(cls)) do
		if valid_mt_ks[key] then
			mt[key] = value
		end
	end

	---
	-- comparison methods:
	-- all of these will set __eq and __ne
	-- equal  (false)  compare tables. tables will be compared using ==
	-- eq     (false)  compare attribs. tables will be deep compared
	-- name   (false)  compare class names
	-- attrib {string} compare by this instance attribute. Can be used with callback
	-- callback {callable} compare objects using this callback
	local __eq = opts.__eq
	if __eq then
		if __eq.equal then
			mt.__eq = comparators.equal
			mt.__ne = comparators.not_equal
		elseif __eq.eq then
			mt.__eq = comparators.eq
			mt.__ne = comparators.not_equal
		elseif __eq.name then
			mt.__eq = comparators.name
			mt.__ne = comparators.not_name
		end
	end

	mt.type = "class"
	mt.class = cls
	mt.instance = true
	mt.name = mtget(cls, "name")
	local parent = get_parent(cls)
	mt.parent = parent

	function mt:__newindex(k, v)
		if valid_mt_ks[k] then
			mt[k] = v
		end
		rawset(self, k, v)
	end

	function mt:__index(k)
		if valid_mt_ks[k] and mt[k] then
			return mt[k]
		elseif parent then
			return parent[k]
		end
	end

	setmetatable(obj, mt)

	if cls.init then
		cls.init(obj, ...)
	elseif parent and parent.init then
		parent.init(obj, ...)
	end

	return obj
end

local function create_class(name, parent, opts)
	if parent then
		assert(is_class(parent), "class expected, got " .. type(parent))
	end

	local cls = copy(Class)
	cls.new = nil
	local mt = {}
	setmetatable(cls, mt)
	mt.type = "class"
	mt.name = name
	mt.parent = parent
	if parent then
		include(cls, parent)
	end

	function mt:__newindex(k, v)
		if valid_mt_ks[k] then
			mt[k] = v
		end
		rawset(self, k, v)
	end

	function mt:__index(k)
		if valid_mt_ks[k] and mt[k] then
			return mt[k]
		elseif parent then
			return parent[k]
		end
	end

	function mt:__call(...)
		return create_instance(self, opts, ...)
	end

	cls.new = function(...)
		return create_instance(cls, opts, ...)
	end

	return cls
end

function Class.new(name, parent, opts)
	return create_class(name, parent, opts)
end

function Mt.__call(_, name, parent, opts)
	return Class.new(name, parent, opts)
end

function class(name, parent)
	local cls = Class(name, parent)
	_G[name] = cls

	return cls
end

function struct(name, parent, opts)
	opts = opts or {}
	opts.struct = true
	return Class.new(name, parent, opts)
end

function datashape(name, parent, opts)
	opts = opts or {}

	if not opts.__eq then
		opts.__eq = { eq = true }
	elseif not opts.__eq.eq and not opts.__eq.equal then
		opts.__eq.eq = true
	end

	return Class.new(name, parent, opts)
end
