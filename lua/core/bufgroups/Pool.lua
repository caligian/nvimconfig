require("core.bufgroups.Bufgroup")
local Pool = Class.new("BufgroupPool")

function Pool:init(name)
	self.name = name
	self.groups = {}
end

function Pool:add(group, event, pattern)
	local bufgroup = Bufgroup(group, event, pattern, self.name)
	self.groups[group] = bufgroup
	bufgroup:enable()

	return self.groups[group]
end

function Pool:remove(group)
	group = self.groups[isa("string", group)]
	if group then
		group:delete()
	end
	self.groups[group] = nil

	return group
end

function Pool:list(telescope)
	if dict.isblank(self.groups) then
		return
	elseif not telescope then
		local out = {}
		for group, value in pairs(self.groups) do
			out[group] = value:list()
		end

		return out
	end

	return {
		results = dict.keys(self.groups),
		entry_maker = function(entry)
			local group = self.groups[entry]
			return {
				value = entry,
				display = sprintf("%s @ %s", entry, table.concat(group.pattern, " :: ")),
				ordinal = -1,
				group = entry,
				pool = group.pool,
				pattern = group.event,
				event = group.pattern,
			}
		end,
	}
end

function Pool:register(group, callback_id, callback)
	Bufgroup.get(self.name, group):register(callback_id, callback)
end

function Pool:create_picker(options)
	local _ = utils.telescope.load()
	local T = utils.telescope
	local mod = T.create_actions_mod()
	local input = vim.fn.input

	function mod.remove(sel)
		local group = Bufgroup.get(sel.pool, sel.group)
		if group then
			group:delete()
		end
		sprintf("Deleted buffer group: %s.%s", sel.pool, sel.group)
	end

	function mod.add(_)
		local pool = input("Pool name % ")
		if #pool == 0 then
			return false
		end

		local group = input("Buffer group name % ")
		if #group == 0 then
			return false
		end

		local pattern = input("Patterns to match (delim = ::) % ")
		if #pattern == 0 then
			return false
		end
		pattern = pattern:split("%s*::%s*")

		Bufgroup(group, "BufRead", pattern, pool)
	end

	function mod.grep(sel)
		local group = Bufgroup.get(sel.pool, sel.group)
		local grep = require("telescope.builtin").grep_string
		local opts = copy(_.ivy)
		opts.grep_open_files = true
		opts.use_regex = true
		opts.search_dirs = array.map(dict.values(group:list()), function(state)
			return state.bufname
		end)
		grep(opts)
	end

	return _.new_picker(self:list(true), {
		function(bufnr)
			local sel = _.get_selected(bufnr)[1]
			local picker = Bufgroup.get(sel.pool, sel.group):create_picker()
			if picker then
				picker:find()
			end
		end,
		{ "n", "/", mod.grep },
		{ "n", "x", mod.remove },
		{ "n", "a", mod.add },
	}, {
		prompt_title = "Buffer group pool: " .. self.name,
	})
end

function Pool.get(name, assrt)
	local pool = Bufgroup.POOLS[name]
	if assrt then
		assert(pool, "invalid pool name " .. name .. " given")
	end
	return pool
end
