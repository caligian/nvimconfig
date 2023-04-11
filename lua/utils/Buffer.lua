--- Buffer object creater. This does not YET cover all the neovim buffer API functions

class("Buffer")

Buffer.ids = Buffer.ids or {}
Buffer._scratch_id = Buffer._scratch_id or 1
utils.buffer = {}
local M = utils.buffer

local function from_percent(current, width, min)
	current = current or vim.fn.winwidth(0)
	width = width or 0.5

	assert(width ~= 0, "width cannot be 0")
	assert(width > 0, "width cannot be < 0")

	if width < 1 then
		required = math.floor(current * width)
	else
		return width
	end

	if min < 1 then
		min = math.floor(current * min)
	else
		min = math.floor(min)
	end

	if required < min then
		required = min
	end

	return required
end

function M.vimsize()
	local scratch = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_call(scratch, function()
		vim.cmd("tabnew")
		local tabpage = vim.fn.tabpagenr()
		width = vim.fn.winwidth(0)
		height = vim.fn.winheight(0)
		vim.cmd("tabclose " .. tabpage)
	end)

	return { width, height }
end

function M.float(bufnr, opts)
	validate({
		win_options = {
			{
				__nonexistent = true,
				["?center"] = "t",
				["?panel"] = "n",
				["?dock"] = "n",
			},
			opts or {},
		},
	})

	opts = opts or {}
	local dock = opts.dock
	local panel = opts.panel
	local center = opts.center
	local focus = opts.focus
	opts.dock = nil
	opts.panel = nil
	opts.center = nil
	opts.style = opts.style or "minimal"
	opts.border = opts.border or "single"
	local editor_size = M.vimsize()
	local current_width = vim.fn.winwidth(0)
	local current_height = vim.fn.winheight(0)
	opts.width = opts.width or current_width
	opts.height = opts.height or current_height
	opts.relative = opts.relative or "editor"
	focus = focus == nil and true or focus

	if center then
		if opts.relative == "editor" then
			current_width = editor_size[1]
			current_height = editor_size[2]
		end
		local width, height = unpack(center)
		width = math.floor(from_percent(current_width, width, 10))
		height = math.floor(from_percent(current_height, height, 5))
		local col = (current_width - width) / 2
		local row = (current_height - height) / 2
		opts.width = width
		opts.height = height
		opts.col = math.floor(col)
		opts.row = math.floor(row)
	elseif panel then
		if opts.relative == "editor" then
			current_width = editor_size[1]
			current_height = editor_size[2]
		end
		opts.row = 0
		opts.col = 1
		opts.width = from_percent(current_width, panel, 5)
		opts.height = current_height
		if reverse then
			opts.col = current_width - opts.width
		end
	elseif dock then
		if opts.relative == "editor" then
			current_width = editor_size[1]
			current_height = editor_size[2]
		end
		opts.col = 0
		opts.row = opts.height - dock
		opts.height = from_percent(current_height, dock, 5)
		opts.width = current_width > 5 and current_width - 2 or current_width
		if reverse then
			opts.row = opts.height
		end
	end

	return vim.api.nvim_open_win(bufnr, focus, opts)
end

function M.winnr(bufnr)
	local winnr = vim.fn.bufwinnr()
	if winnr == -1 then
		return false
	end
	return winnr
end

function M.winid(bufnr)
	local winid = vim.fn.bufwinnr()
	if winid == -1 then
		return false
	end
	return winid
end

function M.exists(bufnr)
	return vim.fn.bufexists(bufnr) ~= 0
end

function M.getwidth(bufnr)
	return vim.fn.winwidth(M.winnr(bufnr))
end

function M.getheight(bufnr)
	return vim.fn.winheight(M.winnr(bufnr))
end

--- Get buffer option
-- @tparam string opt Name of the option
-- @return any
function M.getopt(bufnr, opt)
	local _, out = pcall(vim.api.nvim_buf_get_option, bufnr, opt)
	if out ~= nil then
		return out
	end
end

--- Get buffer option
-- @tparam string var Name of the variable
-- @return any
function M.getvar(bufnr, var)
	local _, out = pcall(vim.api.nvim_buf_get_var, bufnr, var)
	if out ~= nil then
		return out
	end
end

function M.setvar(bufnr, k, v)
	vim.api.nvim_buf_set_var(bufnr, k, v)
end

--- Set buffer variables
-- @tparam table vars dictionary of var name and value
function M.setvars(bufnr, vars)
	dict.each(vars, function(k, v)
		M.setvar(bufnr, k, v)
	end)
	return vars
end

--- Get buffer window option
-- @tparam string opt Name of the option
-- @return any
function M.getwinopt(bufnr, opt)
	local _, out = pcall(vim.api.nvim_win_get_option, M.winid(bufnr), opt)
	if out ~= nil then
		return out
	end
end

--- Get buffer window option
-- @tparam string var Name of the variable
-- @return any
function M.getwinvar(bufnr, var)
	local _, out = pcall(vim.api.nvim_win_get_var, M.winid(bufnr), var)
	if out then
		return out
	end
end

function M.setwinvar(bufnr, k, v)
	vim.api.nvim_win_set_var(M.winid(bufnr), k, v)
end

function M.setwinvars(bufnr, vars)
	dict.each(vars, function(k, v)
		M.setwinvar(k, v)
	end)
	return vars
end

function M.setopt(bufnr, k, v)
	vim.api.nvim_buf_set_option(bufnr, k, v)
end

function M.setopts(bufnr, opts)
	for key, val in pairs(opts) do
		M.setopt(bufnr, key, val)
	end
end

function M.focus(bufnr)
	local winid = M.winid(bufnr)
	if winid then
		vim.fn.win_gotoid(winid)
		return true
	end
end

function M.setwinopt(bufnr, k, v)
	vim.api.nvim_win_set_option(M.winid(bufnr), k, v)
	return v
end

function M.setwinopts(bufnr, opts)
	dict.each(opts, function(k, v)
		M.setwinopt(bufnr, k, v)
	end)
	return opts
end

local function assert_exists(bufnr)
	assert(M.exists(bufnr), "buffer does not exist: " .. bufnr)
end

--- Make a new buffer local mapping.
-- @param mode Mode to bind in
-- @param lhs Keys to bind callback to
-- @tparam function|string callback Callback to be bound to table.keys
-- @tparam[opt] table opts Additional vim.keymap.set options. You cannot set opts.pattern as it will be automatically set by this function
-- @return object Keybinding object
function M.map(bufnr, mode, lhs, callback, opts)
	assert_exists(bufnr)
	opts = opts or {}
	opts.buffer = bufnr
	return Keybinding.map(mode, lhs, callback, opts)
end

--- Create a nonrecursive mapping
-- @see table.map
function M.noremap(bufnr, mode, lhs, callback, opts)
	assert_exists(bufnr)
	opts = opts or {}
	if is_a.s(opts) then
		opts = { desc = opts }
	end
	opts.buffer = bufnr
	opts.noremap = true
	M.map(mode, lhs, callback, opts)
end

--- Split current window and focus this buffer
-- @param[opt='s'] split Direction to split in: 's' or 'v'
function M.split(bufnr, split, opts)
	assert_exists(bufnr)

	opts = opts or {}
	split = split or "s"

	local required
	local reverse = opts.reverse
	local width = opts.resize or 0.3
	local height = opts.resize or 0.3
	local min = 0.1

	-- Use decimal table.values to use percentage changes
	if split == "s" then
		local current = vim.fn.winheight(0)
		required = from_percent(current, height, min)
		if not reverse then
			if opts.full then
				vim.cmd("botright split | b " .. bufnr)
			else
				vim.cmd("split | b " .. bufnr)
			end
		else
			if opts.full then
				vim.cmd(sprintf("botright split | wincmd j | b %d", bufnr))
			else
				vim.cmd(sprintf("split | wincmd j | b %d", bufnr))
			end
		end
		vim.cmd("resize " .. required)
	elseif split == "v" then
		local current = vim.fn.winwidth(0)
		required = from_percent(current, height or 0.5, min)
		if not reverse then
			if opts.full then
				vim.cmd("vert topleft split | b " .. bufnr)
			else
				vim.cmd("vsplit | b " .. bufnr)
			end
		else
			if opts.full then
				vim.cmd(sprintf("vert botright split | b %d", bufnr))
			else
				vim.cmd(sprintf("vsplit | wincmd l | b %d", bufnr))
			end
		end
		vim.cmd("vert resize " .. required)
	elseif split == "f" then
		M.float(bufnr, opts)
	elseif split == "t" then
		vim.cmd(sprintf("tabnew | b %d", bufnr))
	end
end

function M.splitright(bufnr, opts)
	opts = opts or {}
	opts.reverse = nil
	return M.split(bufnr, "s", opts)
end

function M.splitabove(bufnr, opts)
	opts = opts or {}
	opts.reverse = true
	return M.split(bufnr, "s", opts)
end

function M.splitbelow(bufnr, opts)
	opts = opts or {}
	opts.reverse = nil
	return M.split(bufnr, "s", opts)
end

function M.splitleft(bufnr, opts)
	opts = opts or {}
	opts.reverse = true
	return M.split(bufnr, "v", opts)
end

--- Create a buffer local autocommand. The  pattern will be automatically set to '<buffer=%d>'
-- @see autocmd._init
function M.hook(bufnr, event, callback, opts)
	assert_exists(bufnr)

	opts = opts or {}

	return Autocmd(
		event,
		table.merge(opts, {
			pattern = sprintf("<buffer=%d>", bufnr),
			callback = callback,
		})
	)
end

--- Hide current buffer if visible
function M.hide(bufnr)
	local winid = vim.fn.bufwinid(bufnr)
	if winid ~= -1 then
		local current_tab = vim.api.nvim_get_current_tabpage()
		local n_wins = #(vim.api.nvim_tabpage_list_wins(current_tab))
		if n_wins > 1 then
			vim.api.nvim_win_hide(winid)
		end
	end
end

---  Is buffer visible?
--  @return boolean
function M.is_visible(bufnr)
	return vim.fn.bufwinid(bufnr) ~= -1
end

--- Get buffer lines
-- @param startrow Starting row
-- @param tillrow Ending row
-- @return table
function M.lines(bufnr, startrow, tillrow)
	startrow = startrow or 0
	tillrow = tillrow or -1

	validate({
		start_row = { "n", startrow },
		end_row = { "n", tillrow },
	})

	return vim.api.nvim_buf_get_lines(bufnr, startrow, tillrow, false)
end

--- Get buffer text
-- @tparam table start Should be table containing start row and col
-- @tparam table till Should be table containing end row and col
-- @param repl Replacement text
-- @return
function M.text(bufnr, start, till, repl)
	validate({
		start_cood = { "t", start },
		till_cood = { "t", till },
		replacement = { "t", repl },
		repl = { is({ "s", "t" }), repl },
	})

	assert_exists(self)

	if is_a(repl) == "string" then
		repl = vim.split(repl, "[\n\r]")
	end

	local a, b = unpack(start)
	local m, n = unpack(till)

	return vim.api.nvim_buf_get_text(bufnr, a, m, b, n, repl)
end

function M.bind(bufnr, opts, ...)
	opts.buffer = bufnr
	return Keybinding.bind(opts, ...)
end

--- Set buffer lines
-- @param startrow Starting row
-- @param endrow Ending row
-- @param repl Replacement line[s]
function M.setlines(bufnr, startrow, endrow, repl)
	assert(startrow)
	assert(endrow)

	if is_a(repl, "string") then
		repl = vim.split(repl, "[\n\r]")
	end

	vim.api.nvim_buf_set_lines(bufnr, startrow, endrow, false, repl)
end

--- Set buffer text
-- @tparam table start Should be table containing start row and col
-- @tparam table till Should be table containing end row and col
-- @tparam string|table repl Replacement text
function M.set(bufnr, start, till, repl)
	assert(is_a(start, "table"))
	assert(is_a(till, "table"))

	vim.api.nvim_buf_set_text(self.bufnr, start[1], till[1], start[2], till[2], repl)
end

--- Switch to this buffer
function M.switch(bufnr)
	assert_exists(bufnr)
	vim.cmd("b " .. bufnr)
end

--- Load buffer
function M.load(bufnr)
	if vim.fn.bufloaded(bufnr) == 1 then
		return true
	else
		vim.fn.bufload(bufnr)
	end
end

--- Call callback on buffer and return result
-- @param cb Function to call in this buffer
-- @return self
function M.call(bufnr, cb)
	return vim.api.nvim_buf_call(bufnr, cb)
end

--- Get buffer-local keymap.
-- @see buffer_has_keymap
function M.getmap(bufnr, mode, lhs)
	return buffer_has_keymap(bufnr, mode, lhs)
end

--- Return visually highlighted table.range in this buffer
-- @see visualrange
function M.range(bufnr)
	return utils.visualrange(bufnr)
end

function M.linecount(bufnr)
	return vim.api.nvim_buf_line_count(bufnr)
end

--- Return current linenumber
-- @return number
function M.linenum(bufnr)
	return M.call(bufnr, function()
		return vim.fn.getpos(".")[2]
	end)
end

function M.is_listed(bufnr)
	return vim.fn.buflisted(bufnr) ~= 0
end

function M.info(bufnr)
	return vim.fn.getbufinfo(bufnr)[1]
end

function M.wininfo(bufnr)
	if not M.is_visible(bufnr) then
		return
	end
	return vim.fn.getwininfo(M.winid(bufnr))
end

function M.string(bufnr)
	return table.concat(M.lines(bufnr, 0, -1), "\n")
end

function M.getbuffer(bufnr)
	return M.lines(bufnr, 0, -1)
end

function M.setbuffer(bufnr, lines)
	return M.setlines(bufnr, 0, -1, lines)
end

function M.current_line(bufnr)
	return M.call(bufnr, function()
		return vim.fn.getline(".")
	end)
end

function M.lines_till_point(bufnr)
	return M.call(bufnr, function()
		local line = vim.fn.line(".")
		return M.lines(bufnr, 0, line)
	end)
end

function M.append(bufnr, lines)
	return M.setlines(bufnr, -1, -1, lines)
end

function M.prepend(bufnr, lines)
	return M.setlines(bufnr, 0, 0, lines)
end

function M.maplines(bufnr, f)
	return table.map(M.lines(bufnr, 0, -1), f)
end

function M.filter(bufnr, f)
	return table.filter(M.lines(bufnr, 0, -1), f)
end

function M.match(bufnr, pat)
	return table.filter(M.lines(bufnr, 0, -1), function(s)
		return s:match(pat)
	end)
end

function M.readfile(bufnr, fname)
	local s = file.read(fname)
	M.setlines(bufnr, -1, s)
end

function M.insertfile(bufnr, fname)
	local s = file.read(fname)
	M.append(bufnr, s)
end

function M.save(bufnr)
	M.call(bufnr, function()
		vim.cmd("w! %:p")
	end)
end

function M.shell(bufnr, command)
	M.call(bufnr, function()
		vim.cmd(":%! " .. command)
	end)
	return M.lines(bufnr)
end

function Buffer:init(name, scratch)
	local bufnr

	if not name then
		scratch = true
		name = "_scratch_buffer_" .. Buffer._scratch_id + 1
	end

	if is_a.n(name) then
		assert(vim.fn.bufexists(name) ~= 0, "invalid bufnr given: " .. tostring(name))
		bufnr = name
		name = vim.fn.bufname(bufnr)
	else
		bufnr = vim.fn.bufadd(name)
	end

	for key, value in pairs(M) do
		if is_callable(value) then
			self[key] = function(_self, ...)
				return value(_self.bufnr, ...)
			end
		end
	end

	self.bufnr = bufnr
	self.name = name
	self.fullname = vim.fn.bufname(bufnr)
	self.scratch = scratch
	self.wo = {}
	self.o = {}
	self.var = {}
	self.wvar = {}

	if scratch then
		Buffer._scratch_id = Buffer._scratch_id + 1
		self:setopts({
			modified = false,
			buflisted = false,
		})
		if self:getopt("buftype") ~= "terminal" then
			self:setopt("buftype", "nofile")
		else
			self.terminal = true
			self.scratch = nil
		end
	end

	setmetatable(self.var, {
		__index = function(_, k)
			return self:getvar(k)
		end,
		__newindex = function(_, k, v)
			return self:setvar(k, v)
		end,
	})

	setmetatable(self.o, {
		__index = function(_, k)
			return self:getopt(k)
		end,

		__newindex = function(_, k, v)
			return self:setopt(k, v)
		end,
	})

	setmetatable(self.wvar, {
		__index = function(_, k)
			if not self:is_visible() then
				return
			end

			return self:getwinvar(k)
		end,

		__newindex = function(_, k, v)
			if not self:is_visible() then
				return
			end

			return self:setwinvar(k, v)
		end,
	})

	setmetatable(self.wo, {
		__index = function(_, k)
			if not self:is_visible() then
				return
			end

			return self:getwinopt(k)
		end,

		__newindex = function(_, k, v)
			if not self:is_visible() then
				return
			end

			return self:setwinopt(k, v)
		end,
	})

	self:update()
end

function Buffer:delete()
	local bufnr = self.bufnr

	if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
		vim.api.nvim_buf_delete(bufnr, { force = true })
		self.ids[self.bufnr] = nil
	end
end

function Buffer:open_scratch(name, split)
	name = name or "scratch_buffer"
	local buf = Buffer(name, true)
	buf:split(split or "s")

	return buf
end

function Buffer.menu(desc, items, formatter, callback)
	validate({
		description = { is({ "s", "t" }), desc },
		items = { is({ "s", "t" }), items },
		callback = { "f", callback },
		["?formatter"] = { "f", formatter },
	})

	if is_a.s(table.items) then
		table.items = vim.split(items, "\n")
	end

	if is_a.s(desc) then
		desc = vim.split(desc, "\n")
	end

	local b = Buffer()
	local desc_n = #desc
	local s = table.extend(desc, items)
	local lines = table.copy(s)

	if formatter then
		s = table.map(s, formatter)
	end

	local _callback = callback
	callback = function()
		local idx = vim.fn.line(".")
		if idx <= desc_n then
			return
		end

		_callback(lines[idx])
	end

	b:setbuffer(s)

	b.o.modifiable = false

	b:hook("WinLeave", function()
		b:delete()
	end)

	b:bind({ noremap = true, event = "BufEnter" }, {
		"q",
		function()
			b:delete()
		end,
	}, { "<CR>", callback, "Run callback" })

	return b
end

function Buffer.input(text, cb, opts)
	validate({
		text = { is({ "t", "s" }), text },
		cb = { "f", cb },
		["?opts"] = { "t", opts },
	})

	opts = opts or {}

	local split = opts.split or "s"
	local trigger_table = opts.keys or "gx"
	local comment = opts.comment or "#"

	if is_a(text, "string") then
		text = vim.split(text, "\n")
	end

	local buf = Buffer()
	buf:setlines(0, -1, text)

	buf:split(split, { reverse = opts.reverse, resize = opts.resize })

	buf:noremap("n", "gQ", function()
		b:delete()
	end, "Close buffer")

	buf:noremap("n", trigger_keys, function()
		local lines = buf:lines(0, -1)
		local sanitized = {}
		local idx = 1

		table.each(lines, function(s)
			if not s:match("^" .. comment) then
				sanitized[idx] = s
				idx = idx + 1
			end
		end)

		cb(sanitized)
	end, "Execute callback")

	buf:hook("WinLeave", function()
		buf:delete()
	end)
end

function Buffer:update()
	table.update(Buffer.ids, { bufnr }, self)
end
