function apply(f, args)
	return f(unpack(args))
end

function rpartial(f, ...)
	local outer = { ... }
	return function(...)
		local inner = { ... }
		local len = #outer
		for idx, a in ipairs(outer) do
			inner[len + idx] = a
		end

		return f(unpack(inner))
	end
end

function partial(f, ...)
	local outer = { ... }
	return function(...)
		local inner = { ... }
		local len = #outer
		for idx, a in ipairs(inner) do
			outer[len + idx] = a
		end

		return f(unpack(outer))
	end
end

function identity(x)
	return x
end
