--- Tables as arrays - utilties
-- @module array
local types = require("lua-utils.types")
local utils = require("lua-utils.utils")
local array = {}

--------------------------------------------------------------------------------
-- Reverse array
-- @param x array
-- @return array
function array.reverse(x)
	local out = {}
	local j = 1

	for i = #x, 1, -1 do
		out[j] = x[i]
		j = j + 1
	end

	return out
end

--- Pop N items from an array
-- @param t array
-- @param n number of items to pop
-- @return array|any
function array.pop(t, n)
	local out = {}
	for i = 1, n or 1 do
		out[i] = table.remove(t, #t)
	end

	if n == 1 then
		return out[1]
	else
		return out
	end
end

--- Shallow copy array
-- @param x table
-- @return copy of x
function array.copy(x)
	return utils.copy(x)
end

--- Concat all elements of an array with a sep
-- @param x array
-- @param sep separator (default:' ')
-- @return string
function array.concat(x, sep)
	x = x or " "
	return table.concat(x, sep)
end

--- Concat all elements of an array with a sep
-- @param x array
-- @param sep separator (default:' ')
-- @return string
function array.join(x, sep)
	x = x or " "
	return table.concat(x, sep)
end

--- Remove element at index. Modifies the array
-- @param x array
-- @param i index
-- @return ?any element found at index
function array.remove(x, i)
	return table.remove(x, i)
end

--- Sort array. Modifies the array
-- @param x array
-- @param cmp optional callable for comparing
-- @return array
function array.sort(x, cmp)
	table.sort(x, cmp)
	return x
end

--- Is array blank?
-- @param x array
-- @return boolean
function array.isblank(x)
	return #x == 0
end

--- Append elements to array. Modifies the array
-- @param x array
-- @param ... elements to append
-- @return array
function array.append(x, ...)
	local idx = #x
	for i, value in ipairs({ ... }) do
		x[idx + i] = value
	end

	return x
end

--- Append elements to array at index. Modifies the array
-- @param t array
-- @param idx index
-- @param ... elements to append
-- @return array
function array.iappend(t, idx, ...)
	for _, value in ipairs({ ... }) do
		table.insert(t, idx, value)
	end

	return t
end

--- Add elements at the beginning of the array. Modifies the array
-- @param t array
-- @param ... elements to prepend the array with
-- @return array
function array.unshift(t, ...)
	for idx, value in ipairs({ ... }) do
		table.insert(t, idx, value)
	end

	return t
end

--- Convert an element into an array
-- @param x element that is not a table
-- @param force force listify the element?
-- @return table
function array.tolist(x, force)
	if force or type(x) ~= "table" then
		return { x }
	end

	return x
end

--- Convert an element into an array
-- @param x element that is not a table
-- @param force force listify the element?
-- @return table
function array.toarray(x, force)
	return array.tolist(x, force)
end

--- Convert array values to keys
-- @param x array
-- @return dict
function array.todict(x)
	if type(x) ~= "table" then
		return { [x] = x }
	end

	local out = {}
	for _, v in pairs(x) do
		out[v] = v
	end

	return out
end

--- Remove the 1st element n times. Modifies the array
-- @param t array
-- @param times optional number of times (default: 1)
-- @return array
function array.shift(t, times)
	local l = #t
	times = times or 1
	for i = 1, times do
		if i > l then
			return t
		end
		table.remove(t, 1)
	end

	return t
end

--- Find an element in an array using BFS search
-- @param t array
-- @param item any
-- @param test optional test callable taking 2 args
-- @param depth max depth to traverse. -1 for a full search
-- @return key|array[keys]
function array.index(t, item, test, depth)
	depth = depth or -1
	test = test or function(x, y, ks)
		return x == y
	end
	local cache = {}

	local function _index(x, d, layer)
		if cache[x] then
			return cache[x]
		end
		if d == depth then
			return layer
		end

		layer = layer or {}
		local later = {}
		local later_i = 0
		cache[x] = layer

		for i = 1, #x do
			array.append(layer, i)

			local v = x[i]
			if types.is_table(v) then
				later[later_i + 1] = { i, v }
				later_i = later_i + 1
			elseif test(v, item, layer) then
				return layer
			end

			array.pop(layer)
		end

		for i = 1, later_i do
			local k, v = unpack(later[i])
			local out = _index(v, d + 1, array.append(layer, k))

			array.pop(layer)

			if out then
				return out
			end
		end
	end

	return _index(t, 0)
end

--- Apply function on an array
-- @param t array
-- @param f callable accepting two args: index, value
function array.ieach(t, f)
	for _, v in ipairs(t) do
		f(_, v)
	end
end

--- Apply function on an array
-- @param t array
-- @param f callable to run on the value
function array.each(t, f)
	for _, v in ipairs(t) do
		f(v)
	end
end

--- Returns array filtered by a callable
-- @param t array
-- @param f callable to determine the element accepting two args: index, callback
-- @return array of elements found
function array.igrep(t, f)
	local out = {}
	local i = 1

	for k, v in ipairs(t) do
		local o = f(k, v)
		if o then
			out[i] = v
			i = i + 1
		end
	end

	return out
end

-- Returns array filtered by a callable
-- @param t array
-- @param f callable to determine the element accepting two args: index, callback
-- @return array of elements found
function array.grep(t, f)
	local out = {}
	local i = 1
	for _, v in ipairs(t) do
		local o = f(v)
		if o then
			out[i] = v
			i = i + 1
		end
	end

	return out
end

--- Filter an array
-- @param t array
-- @param f callable to act as a filter
-- @return boolean array
function array.filter(t, f)
	local out = {}
	for idx, v in ipairs(t) do
		local o = f(v)
		if o then
			out[idx] = true
		else
			out[idx] = false
		end
	end

	return out
end

--- Filter an array
-- @param t array
-- @param f callable to act as a filter, takes 2 args: index, value
-- @return boolean array
function array.ifilter(t, f)
	local out = {}
	for idx, v in ipairs(t) do
		local o = f(idx, v)
		if o then
			out[idx] = true
		else
			out[idx] = false
		end
	end

	return out
end

--- Apply a callable to an array
-- @param t array
-- @param f callable to transform the array
-- @param in_place if true then transform the array in-place
-- @return array or modified array
function array.map(t, f, in_place)
	local out = {}
	for idx, v in ipairs(t) do
		v = f(v)
		assert(v ~= nil, "non-nil expected")
		if in_place then
			t[idx] = v
		end
		out[idx] = v
	end

	return out
end

--- Apply a callable to an array
-- @param t array
-- @param f callable to transform the array, with 2 args: index, value
-- @param in_place if true then transform the array in-place
-- @return array or modified array
function array.imap(t, f, in_place)
	local out = {}
	for idx, v in ipairs(t) do
		v = f(idx, v)
		assert(v ~= nil, "non-nil expected, got " .. tostring(v))
		if in_place then
			t[idx] = v
		end
		out[idx] = v
	end

	return out
end

--- Get array length
-- @param x array
-- @return number
function array.len(x)
	return #x == 0
end

--- Extend array with other tables or non-tables. Modifies the array
-- @param tbl array to extend
-- @param ... rest of the elements
-- @return array
function array.extend(tbl, ...)
	for i, t in ipairs({ ... }) do
		if type(t) == "table" then
			local n = #tbl
			for j, value in ipairs(t) do
				tbl[n + j] = value
			end
		else
			tbl[#tbl + i] = t
		end
	end

	return tbl
end

--- Compare two arrays/tables
-- @usage
-- -- output: {true, false, false}, false
-- array.compare({1, 2, 3}, {1, 3, 4, 5})
--
-- -- output: {true, false, {true, false}}, false
-- array.compare({1, 2, {3, 4}}, {1, 9, {3, 5}})
--
-- -- output: false
-- array.compare({'a', 'b'}, {'a', 'c'}, nil, true)
--
-- @param a table1
-- @param b table2
-- @param callback to compare element of table1 with that of table2's
-- @param no_state if specified then return false as soon an equality is found
-- @return table[boolean], boolean if no_state is not given else boolen
function array.compare(a, b, callback, no_state)
	local compared = {}
	local state = compared
	local all_equal
	local unique_id = 0
	local cache = {}
	local ok, ffi = pcall(require, "ffi")

	local function hash(x, y)
		if ok then
			local x_ptr = ffi.cast("int*", x)
			local y_ptr = ffi.cast("int*", y)
			local id = array.concat({ x_ptr, ",", y_ptr }, "")

			return id
		end

		x = tostring(unique_id + 1)
		y = tostring(unique_id + 2)
		return (x .. ":" .. y)
	end

	local function cache_get(x, y)
		local id = hash(x, y)

		if not cache[id] then
			cache[id] = true
			unique_id = unique_id + 1
		end
	end

	local function _compare(x, y)
		if cache_get(x, y) then
			return
		end

		local later = {}

		for key, value in pairs(x) do
			local y_value = y[key]
			if not y_value then
				state[key] = false
			elseif types.is_table(y_value) and types.is_table(value) then
				state[key] = {}
				state = state[key]
				later[#later + 1] = { value, y_value }
			elseif callback then
				state[key] = callback(value, y_value)
			else
				state[key] = value == y_value
			end

			for _, v in ipairs(later) do
				_compare(unpack(v))
			end

			all_equal = state[key]
			if no_state and not all_equal then
				return false
			end
		end
	end

	_compare(a, b)

	if no_state then
		return all_equal
	end
	return compared, all_equal
end

--- Return the first N-1 elements in the array.
-- @param t array
-- @param n number of first N-n-1 elements
-- @return array of N-n-1 elements
function array.butlast(t, n)
	n = n or 1
	local len = #t
	local new = {}
	local idx = 1
	for i = 1, len - n do
		new[idx] = t[i]
		idx = idx + 1
	end

	return new
end

--- Return the first N elements
-- @param t array
-- @param n first n element[s]
-- @return any|array
function array.head(t, n)
	if n == 1 then
		return t[1]
	end

	n = n or 1
	local out = {}
	for i = 1, n do
		out[i] = t[i]
	end

	return out
end

--- Return the first N elements
-- @param t array
-- @param n first n element[s]
-- @return any|array
function array.first(t, n)
	return array.head(t, n or 1)
end

--- Return the last N elements in the array
-- @param t array
-- @param n number of last elements. default: 1
-- @return array of N elements defined
function array.last(t, n)
	if n == 1 then
		return t[#t]
	end

	n = n or 1
	local out = {}
	local len = #t
	local idx = 1
	for i = len - (n - 1), len do
		out[idx] = t[i]
		idx = idx + 1
	end

	return out
end

--- Return the last N elements in the array
-- @param t array
-- @param n number of elements. default: 1
-- @return array of N elements defined
function array.tail(t, n)
	return array.last(t, n)
end

--- Return the last N-1-n elements in the array. Like cdr() and nthcdr()
-- @param t array
-- @param n number of last elements. default: 1
-- @return array of N-1-n elements defined
function array.rest(t, n)
	n = n or 1
	local out = {}
	local idx = 1
	for i = n + 1, #t do
		out[idx] = t[i]
		idx = idx + 1
	end

	return out
end

--- Update an array with keys
-- @param tbl array|table
-- @param keys array of keys
-- @param value value to replace with
-- @return value, value-array, array
function array.update(tbl, keys, value)
	keys = array.tolist(keys)
	local len_ks = #keys
	local t = tbl
	local i = 1

	while i < len_ks do
		local k = keys[i]
		local v = t[k]

		if v == nil then
			t[k] = {}
			v = t[k]
		end

		if type(v) == "table" then
			t = v
		else
			return
		end

		i = i + 1
	end

	t[keys[i]] = value

	return value, t
end

--- Get element at path specified by key(s)
-- @param tbl array|table
-- @param ks key|array[keys] to get the element from
-- @param create_path if true then create a table if element is absent
-- @return any
function array.get(tbl, ks, create_path)
	if type(ks) ~= "table" then
		ks = { ks }
	end

	local t = tbl
	local i = 1

	while i < #ks do
		local k = ks[i]
		local v = t[k]

		if v == nil and create_path then
			t[k] = {}
			v = t[k]
		end

		if type(v) == "table" then
			t = t[k]
		else
			break
		end

		i = i + 1
	end

	local n = #ks
	local v = t[ks[n]]
	if v == nil and create_path then
		t[ks[n]] = {}
	end
	if t[ks[n]] then
		return t[ks[n]], t
	end
end

--- Return a subarray specified by index
-- @usage
-- @param t array
-- @param from start index. If negative then N-from
-- @param till end index. If negative then N-till
-- @return array
function array.slice(t, from, till)
	local l = #t
	from = from or 1
	till = till or 0
	till = till == 0 and l or till
	from = from == 0 and l or from
	if from < 0 then
		from = l + from
	end
	if till < 0 then
		till = l + till
	end
	if from > till then
		return {}
	end

	local out = {}
	local idx = 1
	for i = from, till do
		out[idx] = t[i]
		idx = idx + 1
	end

	return out
end

--- Get element at path specified by key(s)
-- @param tbl array|table
-- @param ... key|array[keys] to get the element from
-- @return any
function array.contains(tbl, ...)
	return (array.get(tbl, { ... }))
end

--- Create a table at the path specified by key(s). Modifies the array
-- @param t array
-- @param ... key(s) where the new table shall be made
-- @return array
function array.makepath(t, ...)
	return array.get(t, { ... }, true)
end

--- Return a number range
-- @param from start index
-- @param till end index
-- @param step default: 1
-- @return array
function array.range(from, till, step)
	step = step or 1
	local out = {}
	local idx = 1

	for i = from, till, step do
		out[idx] = i
		idx = idx + 1
	end

	return out
end

--- Zip two arrays element-wise in the form {x, y}
-- @param a array1
-- @param b array2
-- @return array[array[a[i], b[i]]]
function array.zip2(a, b)
	assert(type(a) == "table", "expected table, got " .. tostring(a))
	assert(type(b) == "table", "expected table, got " .. tostring(a))

	local len_a, len_b = #a, #b
	local n = len_a > len_b and len_b or len_a < len_b and len_a or len_a
	local out = {}
	for i = 1, n do
		out[i] = { a[i], b[i] }
	end

	return out
end

--- Delete index from array. Modifies the array
-- @param tbl array
-- @param ... key|key(s)
-- @return any
function array.delete(tbl, ...)
	local ks = { ... }
	local _, t = array.get(tbl, ks)
	if not t then
		return
	end

	local k = ks[#ks]
	local obj = t[k]
	table.remove(t, k)

	return obj
end

--- Check if all the elements are truthy
-- @param t array
-- @return boolean
function array.all(t)
	local is_true = 0
	local n = #t

	for i = 1, n do
		if t[i] then
			is_true = is_true + 1
		end
	end

	return is_true == n
end

--- Check if some elements are truthy
-- @param t array
-- @return boolean
function array.some(t)
	local is_true = 0
	for i = 1, #t do
		if t[i] then
			is_true = is_true + 1
		end
	end
	return is_true > 0
end

-- lua5.1 array.lua
return array
