Process = struct("Process", { "id", "opts", "cmd", "stderr", "stdout", 'exit_code' })

Process.processes = Process.processes or {}

Process.timeout = 100

Process.exception = exception.from_dict {
    invalid_command = "expected valid command",
    shell_not_executable = "shell not executable",
    exited_with_error = "command exited with error",
    interrupted = "process interrupted",
    invalid_id = "invalid job id",
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

function Process.init_before(cmd, opts)
    opts = deepcopy(opts or {})
    opts.env = opts.env or { HOME = os.getenv "HOME", PATH = os.getenv "PATH" }
    opts.cwd = opts.cwd or vim.fn.getcwd()
    opts.stdin = opts.stdin == nil and "pipe" or opts.stdin

    return { cmd = cmd, opts = opts, id = false, stderr = {}, stdout = {} }
end

function Process.init(self)
    local opts = self.opts

    if opts.on_stderr then
        if is_callable(opts.on_stderr) then
            opts.on_stderr = Process._on_stderr(self, opts.on_stderr)
        else
            opts.on_stderr = Process._on_stderr(self)
        end
    end

    if opts.on_exit then
        if is_callable(opts.on_exit) then
            opts.on_exit = Process._on_exit(self, opts.on_exit)
        else
            opts.on_exit = Process._on_exit(self)
        end
    end

    if opts.on_stdout then
        if is_callable(opts.on_stdout) then
            opts.on_stdout = Process._on_stdout(self, opts.on_stdout)
        else
            opts.on_stdout = Process._on_stdout(self)
        end
    end

    return self
end

function Process._on_exit(self, cb)
    return vim.schedule_wrap(function(j, exit_code)
        j = Process.processes[j]
        j.exit_code = exit_code

        if #self.stdout == 1 and #self.stdout[1] == 0 then
            self.stdout = false
        end

        if #self.stderr == 1 and #self.stderr[1] == 0 then
            self.stderr = false
        end

        if cb then
            cb(j, exit_code)
        end
    end)
end

function Process._on_stderr(self, cb)
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
end

function Process._on_stdout(self, cb)
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
end
function Process.send(self, s)
    if not Process.is_running(self) then
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
end

function Process.start(self)
    if Process.is_running(self) then
        return
    end

    local id
    id = vim.fn.jobstart(self.cmd, self.opts)
    local ok, msg = Process.get_status(self, id)

    if not ok and msg then
        msg:throw()
    end

    self.id = id
    Process.processes[id] = self

    return self
end

function Process.stop(self)
    if not Process.is_running(self) then
        return
    end

    vim.fn.chanclose(self.id)
    self.bufnr = nil
    Process.processes[self.id] = false

    return self
end

function Process.get_status(self, timeout)
    if not self.id then
        return
    end

    local id = self.id
    if id == 0 then
        return false, Process.exception.invalid_command
    elseif id == -1 then
        return false, Process.exception.shell_not_executable
    end

    local status = vim.fn.jobwait({ id }, timeout or Process.timeout)[1]
    if status ~= -1 and status ~= 0 then
        if status >= 126 then
            return false, Process.exception.invalid_command
        elseif status == -2 then
            return false, Process.exception.interrupted
        elseif status == -3 then
            return false, Process.exception.invalid_id
        end
    end

    return id
end

function Process.is_running(self)
    self.id = (Process.get_status(self))
    return self.id
end

function Process.if_running(self, callback)
    if not Process.is_running(self) then
        return
    end

    return callback(self)
end

function Process.unless_running(self, callback)
    if Process.is_running(self) then
        return
    end

    return callback(self)
end
