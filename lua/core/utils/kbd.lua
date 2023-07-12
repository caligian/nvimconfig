require("core.utils.autocmd")

kbd = {
	kbds = {},
	exception = {
		duplicate_name = exception("keybinding already exists"),
	},
}

local enable = vim.keymap.set
local delete = vim.keymap.del

function kbd.new(mode, ks, callback, opts)
	if is_a.string(opts) then
		opts = { desc = opts }
	end

	validate({
		mode = { "string", mode },
		keys = { "string", ks },
		callback = { is({ "callable", "string" }), callback },
		opts = {
			{
				opt_event = is({ "string", "array" }),
				opt_pattern = is({ "string", "array" }),
				opt_prefix = "string",
				name = "string",
			},
			opts,
		},
	})

	opts = vim.deepcopy(opts)
	local group
	local name = opts.name

	-- if kbd.kbds[name] then kbd.exception.duplicate_name:throw(name) end

	local other_opts = dict.grep(opts, function(key, _)
		local unrequired = {
			mode = true,
			keys = true,
			callback = true,
			event = true,
			pattern = true,
			name = true,
			once = true,
			leader = true,
			localleader = true,
			prefix = true,
		}
		return not unrequired[key]
	end)

	if opts.leader then
		ks = "<leader>" .. ks
	elseif opts.localleader then
		ks = "<localleader>" .. ks
	elseif opts.prefix then
		ks = opts.prefix .. ks
	end

	kbd.kbds[name] = {
		mode = vim.split(mode, ""),
		keys = ks,
		event = opts.event or false,
		pattern = opts.pattern or false,
		name = name,
		opts = other_opts,
		callback = callback,
		enabled = false,
		autocmd = false,
		enable = function(self)
			if self.enabled then
				return
			elseif self.event and self.pattern then
				self.autocmd = autocmd.new(self.event, {
					pattern = self.pattern,
					name = "kbd." .. self.name,
					callback = function(au)
						local kbd_opts = vim.deepcopy(self.opts)
						kbd_opts.buffer = au.buf
						vim.keymap.set(self.mode, self.keys, self.callback, kbd_opts)
						self.enabled = true
					end,
				})
				self.autocmd:enable()
			else
				vim.keymap.set(self.mode, self.keys, self.callback, self.opts)
				self.enabled = true
			end

			return self
		end,
		disable = function(self, current)
			if not self.enabled then
				return
			elseif self.autocmd then
				if not self.enabled then
					return
				end

				self.autocmd:disable()
				array.each(self.autocmd.buffers, function(buf)
					vim.keymap.del(self.mode, self.keys, { buffer = buf })
				end)
			else
				vim.keymap.del(self.mode, self.keys, { buffer = current })
			end

			self.enabled = false

			return self
		end,
	}

	return kbd.kbds[name]
end

function kbd.map_with_opts(opts, callback)
	validate({
		preset_opts = { "dict", opts },
		names_with_callbacks = { "dict", callback },
	})

	opts = deepcopy(opts)
	local apply = opts.apply
	opts.apply = nil

	dict.each(callback, function(kbd_name, callback)
		local ks, cb, rest = unpack(callback)
		if is_a.string(rest) then
			rest = { desc = rest }
		end
		rest = dict.merge(vim.deepcopy(rest or {}), opts)
		rest.name = rest.name or kbd_name
		local mode = rest.mode or "n"

		if apply then
			mode, ks, cb, rest = apply(mode, ks, cb, rest)
		end

		kbd.new(mode, ks, cb, rest):enable()
	end)
end

function kbd.map(...)
	return kbd.new(...):enable()
end

function kbd.noremap(mode, keys, cb, opts)
	if is_a.string(opts) then
		opts = { desc = opts }
	end

	opts = vim.deepcopy(opts or {})
	opts.remap = false
	opts.noremap = true

	return kbd.map(mode, keys, cb, opts)
end

function kbd.map_groups(groups)
	local all_opts = deepcopy(groups.opts or {})
	local all_apply = groups.apply
	groups.apply = nil
	groups.opts = nil
	local new = {}

	dict.each(groups, function(group_name, group_spec)
		if group_name == "opts" or group_name == "inherit" or group_name == "apply" then
			return
		end

		local opts = group_spec.opts and deepcopy(group_spec.opts)
		local inherit = group_spec.inherit
		local apply = group_spec.apply
		group_spec.opts = nil
		group_spec.inherit = nil
		group_spec.apply = nil

		if opts or inherit then
			if opts and inherit then
				dict.merge(opts, all_opts)
			elseif not opts then
				opts = all_opts
			end

			opts.apply = function(mode, ks, cb, rest)
				if apply and all_apply then
					return all_apply(apply(mode, ks, cb, rest))
				elseif apply then
					return apply(mode, ks, cb, rest)
				else
					return mode, ks, cb, rest
				end
			end

			dict.each(group_spec, function(kbd_name, kbd_spec)
				local ks, cb, rest = unpack(kbd_spec)
				if is_a.string(rest) then
					rest = { desc = rest }
				end

				rest = rest or {}
				if opts then
					dict.merge(rest, opts)
				end
				rest.apply = nil

				rest.name = group_name .. "." .. kbd_name
				local mode = rest.mode or "n"
				new[rest.name] = { mode, ks, cb, rest }
			end)
		else
			dict.each(group_spec, function(kbd_name, kbd_spec)
				if is_a.string(kbd_spec[4]) then
					kbd_spec[4] = { desc = kbd_spec[4] }
				end

				local options = kbd_spec[4] or {}
				options.name = group_name .. "." .. kbd_name
				kbd_spec[4] = options
				local mode, ks, cb, rest = unpack(kbd_spec)

				rest = rest or {}
				if opts then
					dict.merge(rest, opts)
				end
				rest.apply = nil
				rest.name = group_name .. "." .. kbd_name

				if apply and all_apply then
					mode, ks, cb, rest = all_apply(apply(mode, ks, cb, rest))
				elseif apply then
					mode, ks, cb, rest = apply(mode, ks, cb, rest)
				end

				new[rest.name] = { mode, ks, cb, rest }
			end)
		end
	end)

	dict.each(new, function(_, spec)
		kbd.map(unpack(spec))
	end)

	return new
end

function kbd.map_group(group, spec)
	return kbd.map_groups({ [group] = spec })
end
