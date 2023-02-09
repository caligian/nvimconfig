class('REPL')

REPL.id = REPL.id or {}
REPL.buffer = REPL.buffer or {}
REPL.commands = REPL.commands or {}

for ft, conf in pairs(user.lang.langs) do
	if conf.commands.repl then REPL.commands[ft] = conf.commands.repl end
end

V.require('user.repl')

local repl = REPL

function repl.is_visible(self)
	local winnr = vim.fn.bufwinnr(self.bufnr)
	return winnr ~= -1
end

function repl.status(self)
	local id = self.id
	id = vim.fn.jobwait({ id }, 0)[1]

	if id == -1 then
		return 'running'
	elseif id == -2 then
		return 'interrupted'
	else
		return false
	end
end

function repl.is_valid(self) return self:status() ~= false end

function repl.is_running(self) return self:status() == 'running' end

function repl.is_interrupted(self) return self:status() == 'interrupted' end

function repl.stop(self)
	local id = self.id
	if not self:is_running() then return end
	id = self.id
	vim.fn.chanclose(id)
	self.running = false
	self:hide()

	if vim.fn.bufexists(self.bufnr) == 1 then vim.api.nvim_buf_delete(self.bufnr, { force = true }) end
end

function repl.stopall()
	for _, r in pairs(repl.buffer) do
		r:stop()
	end
end

local function get(name)
	local r = repl.id[name]
	if r and r.running then
		return r
	else
		return false
	end
end

function repl._init(self, name, opts)
	local r = get(name)
	if r then return r end

	opts = opts or {}
	if not name then
		self.name = vim.bo.filetype
	else
		self.name = name
	end

	for k, v in pairs(opts) do
		self[k] = v
	end
end

local function start(bufnr, cmd)
	return vim.api.nvim_buf_call(bufnr, function()
		vim.cmd('term')
		local id = vim.b.terminal_job_id
		vim.bo.buflisted = false
		vim.wo.number = false
		vim.cmd('set nomodified')
		vim.api.nvim_chan_send(id, cmd .. '\r')

		return id
	end)
end

function repl.start(self, opts)
	opts = opts or {}
	V.merge_keepleft(opts, self)
	opts.name = opts.name or vim.bo.filetype
	opts.cmd = opts.cmd or repl.commands[opts.name]
	local name, cmd = opts.name, opts.cmd

	assert(cmd, 'No command provided')

	local r = get(name)
	if opts.force then
		r:stop()
		r:start(opts)
	elseif r and r.id then
		return r
	end

	local buf = vim.api.nvim_create_buf(false, true)
	local id = start(buf, cmd)
	self.id = id
	self.running = true
	self.command = cmd
	self.name = name
	self.bufnr = buf
	repl.id[id] = self
	repl.id[name] = self
	repl.buffer[buf] = self

	return self
end

function repl.hide(self)
	if not self:is_visible() then return end

	local bufnr = self.bufnr
	vim.api.nvim_buf_call(bufnr, function()
		local winid = vim.fn.bufwinid(bufnr)
		vim.fn.win_gotoid(winid)
		vim.cmd('hide')
	end)
end

local function ensure(self)
	if self:is_running() then return self end
	self:start()
end

function repl.split(self, direction)
	ensure(self)

	if self:is_visible() then return end

	direction = direction or 's'
	local terminal_buf = self.bufnr
	if direction == 's' then
		local height = vim.fn.winheight(0) / 3
		local count = math.floor(height)
		vim.cmd('split | wincmd j | b ' .. terminal_buf .. ' | resize ' .. count)
	else
		local width = vim.fn.winwidth(0) / 3
		local count = math.floor(width)
		vim.cmd('vsplit | wincmd l | b ' .. terminal_buf .. ' | vertical resize ' .. count)
	end
end

function repl.send(self, s)
	ensure(self)

	local id = self.id
	if V.is_type(s, 'table') then s = table.concat(s, '\n') end
	s = s .. '\r'
	vim.api.nvim_chan_send(id, s)
end

function repl.send_current_line(self, src_bufnr)
	src_bufnr = src_bufnr or vim.fn.bufnr()
	vim.api.nvim_buf_call(src_bufnr, function() self:send(vim.fn.getline('.')) end)
end

function repl.send_buffer(self, src_bufnr)
	src_bufnr = src_bufnr or vim.fn.bufnr()
	self:send(vim.api.nvim_buf_get_lines(src_bufnr, 0, -1, false))
end

function repl.send_till_point(self, src_bufnr)
	src_bufnr = src_bufnr or vim.fn.bufnr()
	vim.api.nvim_buf_call(src_bufnr, function()
		local line = vim.fn.line('.')
		self:send(vim.api.nvim_buf_get_lines(src_bufnr, 0, line, false))
	end)
end

function repl.send_visual_range(self, src_bufnr)
	src_bufnr = src_bufnr or vim.fn.bufnr()
	return self:send(V.get_visual_range(src_bufnr))
end
