class 'Keybinding'

K = Keybinding
K.ids = {}
K.defaults = {}
local id = 1

local function parse_opts(opts)
	opts = opts or {}
	local parsed = { au = {}, kbd = {}, misc = {} }

	teach(opts, function(k, v)
		-- For autocommands
		if match(k, "pattern", "once", "nested", "group") then
			parsed.au[k] = v
		elseif match(k, "event", "name", "mode", "prefix", "leader", "localleader", "cond") then
			parsed.misc[k] = v
		else
			parsed.kbd[k] = v
		end
	end)

	return parsed
end

function K.update(self)
	update(Keybinding.ids, self.id, self)

	if self.buffer then
		update(Keybinding.buffer, { self.buffer, self.id }, self)
	end

	if self.name then
		Keybinding.defaults[self.name] = self
	end

	return self
end

---
-- Create a keybinding
-- @tparam string|table mode Mode
-- @tparam string lhs LHS
-- @tparam string|function cb Callback/RHS
-- @tparam table rest Rest of the optional arguments
-- @usage K(mode, lhs, cb, {
--   -- Any Autocmd-compatible params other than event
--   -- event and pattern when specified marks a local keybinding
--   event = string|table

--   -- Buffer local mapping. Pass a bufnr
--   buffer = number

--   -- Other keyboard args
--   mode = string|table = 'n'

--   -- Leader, localleader and prefix which will automatically modify LHS
--   localleader = boolean
--   leader = boolean
--
--   -- If provided then this object will be hashed in Keybinding.defaults
--   -- This WILL get overwritten and is NOT a preferred way to manipulate keybindings already set
--   name = string
--
--   -- Any other optional args required by vim.keymap.set
-- })
-- @see autocmd
-- @return object
function K._init(self, mode, lhs, cb, rest)
	validate { 
		mode = {{'s', 't'}, mode},
		lhs = {'s', lhs},
		cb = {{'s', 'f'}, cb},
		['?rest'] = {'t', rest}
	}

	rest = rest or {}
	mode = mode or rest.mode or "n"

	if is_a.s(mode) then
		mode = vim.split(mode, "")
	end

	if is_a.s(rest) then
		rest = { desc = rest }
	end

	rest = rest or {}
	rest = parse_opts(rest)
	local au, kbd, misc = rest.au, rest.kbd, rest.misc
	local leader = misc.leader
	local localleader = misc.localleader
	local prefix = misc.prefix
	local buffer = kbd.buffer == true and vim.fn.buffer() or kbd.buffer
	local event = misc.event
	local pattern = au.pattern
	local name = misc.name
	local cond = misc.cond
	local _cb = cb

	if leader then
		lhs = "<leader>" .. lhs
	elseif localleader then
		lhs = "<localleader>" .. lhs
	elseif prefix then
		lhs = prefix .. lhs
	end

	self.id = id
	id = id + 1

	if event and pattern then
		local callback = function()
			kbd.buffer = vim.fn.bufnr()
			vim.keymap.set(mode, lhs, cb, kbd)
			self.enabled = true
			self:update(self)
		end
		au.callback = callback
		self.autocmd = Autocmd(event, au)
	elseif buffer then
		vim.keymap.set(mode, lhs, cb, kbd)
		au.pattern = "<buffer=" .. buffer .. ">"
		local callback = function()
			self.enabled = true
			self:update(self)
		end
		au.callback = callback
		self.autocmd = Autocmd("BufEnter", au)
	else
		vim.keymap.set(mode, lhs, cb, kbd)
		self.enabled = true
		self:update(self)
	end

	self.desc = kbd.desc
	self.mode = mode
	self.lhs = lhs
	self.callback = cb
	self.name = name
	local o = {}

	merge(o, au)
	merge(o, misc)
	merge(o, kbd)

	self.opts = o

	return self
end

--- Disable keybinding
function K.disable(self)
	if not self.enabled then
		return
	end

	if self.autocmd then
		self.autocmd:delete()
		self.autocmd = nil
		if self.opts.buffer then
			for _, mode in ipairs(self.mode) do
				vim.api.nvim_buf_del_keymap(self.opts.buffer, mode, self.lhs)
			end
		end
		self.enabled = false
	else
		for _, mode in ipairs(self.mode) do
			vim.api.nvim_del_keymap(mode, self.lhs)
		end
		self.enabled = false
	end

	return self
end

--- Delete keybinding
function K.delete(self)
	if not self.enabled then
		return
	end

	self:disable()
	Keybinding.ids[self.id] = nil

	if self.name then
		Keybinding.defaults[self.name] = nil
	end

	return self
end

---
-- Helper function for Keybinding() to set keybindings with default options
-- @tparam table opts Default options
-- @usage Keybinding.bind(
--   -- Valid default options:
--   -- leader, localleader, noremap, event, pattern, buffer, prefix, mode
--   opts,

--   -- If opts is present here then take precedence over defaults
--   -- Most generally, you will need this to other specifics as it will be merged with defaults
--   {lhs, cb, desc/opts},
--   ...
-- )
-- @return ?self Return object if only form was passed
function K.bind(opts, ...)
	opts = opts or {}
	local args = { ... }
	local bind = function(kbd)
		validate { 
			kbd_spec = {'table', kbd}
		}
		assert(#kbd >= 2)

		local lhs, cb, o = unpack(kbd)
		validate {
			lhs = {'s', lhs},
			cb = {{'s', 'f'}, cb}
		}

		o = o or {}
		if is_a.s(o) then
			o = { desc = o }
		end
		validate {
			kbd_opts = {'table', o}
		}

		for key, value in pairs(opts) do
			if not o[key] then
				o[key] = value
			end
		end

		local mode = o.mode or "n"
		kbd[3] = o

		return K(mode, unpack(kbd))
	end

	if #args == 1 then
		return bind(args[1])
	else
		each(args, bind)
	end
end

--- Simple classmethod that does the same thing as Keybinding()
function K.map(mode, lhs, cb, opts)
	return K(mode, lhs, cb, opts)
end

--- Same as map but sets noremap to true
function K.noremap(mode, lhs, cb, opts)
	opts = opts or {}
	if is_a.s(opts) then
		opts = { desc = opts }
	end
	opts.noremap = true

	return K(mode, lhs, cb, opts)
end

--- Replace current callback with a new one
-- @param cb Callback to replace with
function K.replace(self, cb)
	assert(cb)

	self:delete()

	return K(self.mode, self.lhs, cb, lmerge(opts or {}, self.opts))
end
