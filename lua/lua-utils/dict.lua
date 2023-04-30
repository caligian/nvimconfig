--- Tables as dictionaries
local types = require("lua-utils.types")
local utils = require("lua-utils.utils")
local array = require("lua-utils.array")

--------------------------------------------------------------------------------
local dict = {}

--- Shallow copy table
-- @param x table
-- @return table
function dict.copy(x)
	return utils.copy(x)
end

--- Get dict values
-- @param t table
-- @return array[values]
function dict.values(t)
	local out = {}
	local i = 1
	for _, value in pairs(t) do
		out[i] = value
		i = i + 1
	end

	return out
end

--- Get dict keys
-- @param t table
-- @param sort sort keys?
-- @param cmp sorter callable(a, b)
-- @return array[keys]
function dict.keys(t, sort, cmp)
	local out = {}
	local i = 1

	for key, _ in pairs(t) do
		out[i] = key
		i = i + 1
	end

	if sort then
		return array.sort(out, cmp)
	end

	return out
end

--- Is dict blank?
-- @param t dict
-- @return boolean
function dict.isblank(t)
	return #dict.keys(t) == 0
end

--- Return dict filtered by a callable
-- @param t dict
-- @param f callable to determine the element accepting two args: key, callback
-- @return dict of elements found
function dict.grep(t, f)
	local out = {}

	for k, v in pairs(t) do
		local o = f(k, v)
		if o then
			out[k] = v
		end
	end

	return out
end

--- Return boolean dict filtered by a callable
-- @param t dict
-- @param f callable to determine the element accepting two args: key, callback
-- @return dict
function dict.filter(t, f)
	local out = {}
	for idx, v in pairs(t) do
		local o = f(idx, v)
		if o then
			out[idx] = v
		else
			out[idx] = false
		end
	end

	return out
end

--- Return dict transformed by a callable
-- @param t dict
-- @param f callable to determine the element accepting two args: key, callback
-- @param in_place if true then modify the dict in place
-- @return dict
function dict.map(t, f, in_place)
	local out = {}
	for k, v in pairs(t) do
		local o = f(k, v)
		assert(o ~= nil, "non-nil expected")
		if in_place then
			t[k] = o
		end
		out[k] = o
	end

	return out
end

--- Return zipped dict keys and items
-- @param t dict
-- @return array[key, value]
function dict.items(t)
	local out = {}
	local i = 1
	for key, val in pairs(t) do
		out[i] = { key, val }
		i = i + 1
	end

	return out
end

--- Get dict length
-- @param t dict
-- @return length
function dict.len(t)
	return #dict.keys(t)
end

--- Compare two dicts
-- @param a table1
-- @param b table2
-- @param callback to compare element of table1 with that of table2's
-- @param no_state if specified then return false as soon an equality is found
-- @see array.compare
-- @return table[boolean], boolean if no_state is not given else boolen
function dict.compare(a, b, callback, no_state)
	return array.compare(a, b, callback, no_state)
end

--- Update an dict with keys
-- @param tbl dict|table
-- @param keys dict of keys
-- @param value value to replace with
-- @return value, value-dict, dict
function dict.update(tbl, keys, value)
	return array.update(tbl, keys, value)
end

--- Find an element in a dict using BFS search
-- @param t dict
-- @param item any
-- @param test optional test callable taking 2 args
-- @param depth max depth to traverse. -1 for a full search
-- @return key|array[keys]
function dict.index(t, item, test, depth)
	depth = depth or -1
	test = test or function(x, y)
		return x == y
	end
	local cache = {}

	local function _index(x, d, layer)
		if cache[x] then
			return
		end
		if d == depth then
			return
		end

		local ks = dict.keys(x)
		local n = #ks
		cache[x] = true
		layer = layer or {}
		local later = {}
		local later_i = 0

		for i = 1, n do
			local k = ks[i]
			local v = x[k]

			if types.is_table(v) then
				later[later_i + 1] = k
				later_i = later_i + 1
			elseif test(v, item) then
				return array.append(layer, k)
			end
		end

		for i = 1, later_i do
			array.append(layer, ks[i])
			local out = _index(x[later[i]], d + 1, layer)
			if out then
				return out
			else
				array.pop(layer)
			end
		end
	end

	return _index(t, 0)
end

--- Get element at path specified by key(s)
-- @param tbl dict|table
-- @param ks key|array[keys] to get the element from
-- @param create_path if true then create a table if element is absent
-- @return any
function dict.get(tbl, ks, create_path)
	return array.get(tbl, ks, create_path)
end

--- Get element at path specified by key(s)
-- @param tbl dict|table
-- @param ... key|dict[keys] to get the element from
-- @return any
function dict.contains(tbl, ...)
	return (dict.get(tbl, { ... }))
end

--- Create a table at the path specified by key(s). Modifies the dict
-- @param t dict
-- @param ... key(s) where the new table shall be made
-- @return dict
function dict.makepath(t, ...)
	return dict.get(t, { ... }, true)
end

--- Apply callable to a dict
-- @param t dict
-- @param f callable with 2 args: key, value
function dict.each(t, f)
	for key, value in pairs(t) do
		f(key, value)
	end
end

--- Merge two dicts but keep the elements if they already exist
-- @param ... dicts
-- @return merged dict
function dict.lmerge(...)
	local cache = {}

	local function _merge(t1, t2)
		local later = {}

		dict.each(t2, function(k, v)
			local a, b = t1[k], t2[k]
			if cache[a] then
				return
			end

			if a == nil then
				t1[k] = v
			elseif types.typeof(a) == "table" and types.typeof(b) == "table" then
				cache[a] = true
				array.append(later, { a, b })
			end
		end)

		array.each(later, function(next)
			_merge(unpack(next))
		end)
	end

	local args = { ... }
	local l = #args
	local start = args[1]

	for i = 2, l do
		_merge(start, args[i])
	end

	return start
end

--- Merge two dicts
-- @param ... dicts
-- @return merged dict
function dict.merge(...)
	local cache = {}

	local function _merge(t1, t2)
		local later = {}

		dict.each(t2, function(k, v)
			local a, b = t1[k], t2[k]
			if cache[a] then
				return
			end

			if a == nil then
				t1[k] = v
			elseif types.typeof(a) == "table" and types.typeof(b) == "table" then
				cache[a] = true
				array.append(later, { a, b })
			else
				t1[k] = v
			end
		end)

		array.each(later, function(vs)
			_merge(unpack(vs))
		end)
	end

	local args = { ... }
	local l = #args
	local start = args[1]

	for i = 2, l do
		_merge(start, args[i])
	end

	return start
end

--- Remove an element by key(s)
-- @param x dict
-- @param ks key|dict[keys]
-- @return any
function dict.delete(x, ks)
	local _, t = dict.get(x, ks)
	if not t then
		return
	end

	local k = ks[#ks]
	local obj = t[k]
	t[k] = nil

	return obj
end

return dict
