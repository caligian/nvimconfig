--- Misc utilities
-- @module utils
local utils = {}

--- Get metatable or metatable key
-- @param obj table
-- @param k key
-- @return metatable or metatable[k] or nil
function utils.mtget(obj, k)
	if type(obj) ~= "table" then
		return
	end
	local mt = getmetatable(obj)
	if not mt then
		return
	end
	if k then
		return mt[k]
	end
	return mt
end

--- Set metatable or metatable key
-- @param obj table
-- @param k key
-- @param v value
-- @return ?any
function utils.mtset(obj, k, v)
	if type(obj) ~= "table" then
		return
	end
	local mt = getmetatable(obj)
	if not mt then
		return
	end
	if k and v then
		mt[k] = v
		return v
	end
end

--- Shallow copy a table
-- @param obj table
-- @return obj
function utils.copy(obj)
	local out = {}
	for key, value in pairs(obj) do
		out[key] = value
	end
	return out
end

return utils
