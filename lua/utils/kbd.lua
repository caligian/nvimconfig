class('Keybinding')

Keybinding.id = Keybinding.id or {}
Keybinding.buffer = Keybinding.buffer or {}

-- This is a factory method, therefore not all keys can be passed
-- opts [table]
-- keys:
-- mode table[string] | string
-- event table[string] | string
-- pattern table[string] | string
-- leader boolean
-- localleader boolean
function Keybinding._init(self, opts)
	opts = opts or {}

	self.mode = opts.mode or 'n'
	self.event = opts.event
	self.pattern = opts.pattern
	self.leader = opts.leader
	self.localleader = opts.localleader
	self.buffer = opts.buffer
	self.prefix = opts.prefix
	self.enabled = false

	return self
end

local function update(self)
	local lhs = self.lhs
	local bufnr = self.bufnr

	for _, i in ipairs(V.ensure_list(self.mode)) do
		V.makepath(Keybinding, i, lhs)

		if bufnr then
			V.append(Keybinding[i][lhs], self)
			V.makepath(Keybinding.buffer, bufnr, i, lhs)
			V.append(Keybinding.buffer[bufnr][i][lhs], self)
		else
			V.append(Keybinding[i][lhs], self)
		end
	end

	return self
end

local function get_kbd_opts(opts)
	local new = {}
	for key, value in pairs(opts) do
		if key ~= 'event' and key ~= 'pattern' and key ~= 'prefix' and key ~= 'buffer' and key ~= 'once' and key ~= 'nested' and key ~= 'group' and key ~= 'clear' and key ~= 'leader' and key ~= 'mode' and key ~= 'localleader' then new[key] = value end
	end

	return new
end

-- This is the main function
-- You can still override the options provided to Keybinding()
local function bind(self, lhs, callback, opts)
	assert(callback, 'No callback provided')
	assert(lhs, 'No LHS provided')

	if V.isstring(opts) then opts = { desc = opts } end

	-- Every keybinding is a new one
	opts = opts or {}
	self = vim.deepcopy(self)
	local leader = opts.leader or self.leader
	local localleader = opts.localleader or self.localleader
	local prefix = opts.prefix or self.prefix

	local event = opts.event or self.event
	local pattern = opts.pattern or self.pattern
	local mode = opts.mode or self.mode

	---
	if leader then
		lhs = '<leader>' .. lhs
	elseif localleader then
		lhs = '<localleader>' .. lhs
	elseif prefix then
		lhs = prefix .. lhs
	end

	---
	if event and pattern then
		Autocmd('Global', event, pattern, function()
			self.enabled = true
			self.buffer = vim.fn.bufnr()
			vim.keymap.set(mode, lhs, callback, get_kbd_opts(opts))
		end, {
			once = self.once,
			nested = self.nested,
		})
	else
		local buffer = opts.buffer or self.buffer
		opts.buffer = buffer
		vim.keymap.set(mode, lhs, callback, get_kbd_opts(opts))

		self.buffer = buffer
		self.enabled = true
	end

	-- We don't need these keys
	self.leader = nil
	self.localleader = nil
	self.prefix = nil

	---
	self.lhs = lhs
	self.callback = callback
	self.event = event
	self.pattern = self.pattern
	self.mode = mode
	self.opts = opts

	---
	return update(self)
end

function Keybinding.bind(self, keys)
	for _, k in ipairs(keys) do
		assert(types.is_type(k, 'table'))
		assert(#k >= 2, 'Need {lhs, callback, [opt]}')
		bind(self, unpack(k))
	end
end

function Keybinding.disable(self)
	if not self.enabled then return self end

	local lhs = self.lhs
	local bufnr = self.bufnr

	for _, m in ipairs(self.mode) do
		if bufnr then
			vim.api.nvim_buf_del_keymap(bufnr, m, lhs)
		else
			vim.api.nvim_del_keymap(m, lhs)
		end
	end

	self.enabled = false
	return self
end

function Keybinding.map(mode, lhs, callback, opts) return Keybinding({ mode = mode }):bind({ { lhs, callback, opts } }) end

function Keybinding.noremap(mode, lhs, callback, opts)
	opts = opts or {}
	opts.noremap = true
	return Keybinding.map(mode, lhs, callback, opts)
end
