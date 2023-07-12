--- vim.fn.jobstart class wrapper for async job control
-- @classmod Process

process = {
	processes = {},
	timeout = 30,
	exception = {
		invalid_command = exception("expected valid command"),
		shell_not_executable = exception("shell not executable"),
		exited_with_error = exception("command exited with error"),
		interrupted = exception("process interrupted"),
		invalid_id = exception("invalid job id"),
	},
}

local function parse(d, out)
	if type(d) == "string" then
		d = vim.split(d, "\n")
	elseif type(d) == "table" then
		for _, s in ipairs(d) do
			s = vim.split(s, "\n")
			array.extend(out, s)
		end
	end
end

function process.new(cmd, opts)
	opts = deepcopy(opts or {})
	opts.env = opts.env or { HOME = os.getenv("HOME"), PATH = os.getenv("PATH") }
	opts.cwd = opts.cwd or vim.fn.getcwd()
	opts.stdin = opts.stdin == nil and "pipe" or opts.stdin

	local self = {
		id = false,
		cmd = cmd,
		opts = opts,
		_on_exit = function(self, cb)
			return vim.schedule_wrap(function(j, exit_code)
				j = process.processes[j]
				j.exited = true
				j.exit_code = exit_code

				if cb then
					cb(j, exit_code)
				end
			end)
		end,
		_on_stderr = function(self, cb)
			self.stderr = self.stderr or {}
			local stderr = self.stderr

			return vim.schedule_wrap(function(_, d)
				if d then
					parse(d, self.stderr)
				end
				if cb then
					cb(self, d)
				end
			end)
		end,
		_on_stdout = function(self, cb)
			self.stdout = self.stdout or {}
			local stdout = self.stdout
			return vim.schedule_wrap(function(_, d)
				if d then
					parse(d, self.stdout)
				end
				if cb then
					cb(self, d)
				end
			end)
		end,
		send = function(self, s)
			if not self:is_running() then
				return
			end

			local id = self.id
			if is_a.string(s) then
				s = vim.split(s, "[\n\r]+")
			end
			if self.on_input then
				s = self.on_input(s)
			end

			s[#s + 1] = "\n"
			s = array.map(s, string.trim)

			return vim.api.nvim_chan_send(id, table.concat(s, "\n"))
		end,
		start = function(self)
			if self:is_running() then
				return
			end

			local id
			id = vim.fn.jobstart(self.cmd, self.opts)
			local ok, msg = self:get_status(id)

			if not ok and msg then
				msg:throw()
			end

			self.id = id
			dict.update(process.processes, { id }, self)

			return self
		end,
		stop = function(self)
			if not self:is_running() then
				return
			end

			vim.fn.chanclose(self.id)
			self.bufnr = nil
			process.processes[self.id] = false

			return self
		end,
		get_status = function(self, timeout)
			if not self.id then
				return
			end

			local id = self.id
			if id == 0 then
				return false, process.exception.invalid_command
			elseif id == -1 then
				return false, process.exception.shell_not_executable
			end

			local status = vim.fn.jobwait({ id }, timeout or process.timeout)[1]
			if status ~= -1 and status ~= 0 then
				if status >= 126 then
					return false, process.exception.invalid_command
				elseif status == -2 then
					return false, process.exception.interrupted
				elseif status == -3 then
					return false, process.exception.invalid_id
				end
			end

			return id
		end,
		is_running = function(self)
			self.id = (self:get_status())
			return self.id
		end,
		if_running = function(self, callback)
			if not self:is_running() then
				return
			end
			return callback(self)
		end,
		unless_running = function(self, callback)
			if self:is_running() then
				return
			end
			return callback(self)
		end,
	}

	if not opts.on_stderr then
		opts.on_stderr = self:_on_stderr()
	else
		local current = opts.on_stderr
		opts.on_stderr = self:_on_stderr(current)
	end

	if not opts.on_stdout then
		opts.on_stdout = self:_on_stdout()
	else
		local current = opts.on_stdout
		opts.on_stdout = self:_on_stdout(current)
	end

	if not opts.on_exit then
		opts.on_exit = self:_on_exit()
	else
		local current = opts.on_exit
		opts.on_exit = self:_on_exit(current)
	end

	return self
end

function process.stop_all()
	dict.each(process.processes, function(_, obj)
		if obj:is_running() then
			obj:stop()
		end
	end)
end
