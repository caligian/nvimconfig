local uv = require 'luv'

builtin.makepath(builtin, 'process')
builtin.process = class.Process()
local process = builtin.process
builtin.makepath(process, 'pid')

function process._on_exit(self)
    return vim.schedule_wrap(function(code, signal)
        self.exit_code = code
        self.signal = signal
    end)
end

function process._on_stderr(self)
    return vim.schedule_wrap(function(err, data)
        builtin.makepath(self, 'stderr')
        if err then
            builtin.append(self.stderr, err)
        end
        if data then
            builtin.append(self.stderr, data)
        end
    end)
end

function process._on_stdout(self)
    return vim.schedule_wrap(function(err, data)
        builtin.makepath(self, 'stdout')
        if err then
            builtin.append(self.stdout, err)
        end
        if data then
            builtin.append(self.stdout, data)
        end
    end)
end

function process.write(self, s)
    if self.shutdown then
        return
    end
    uv.write(self.stdin_pipe, s)

end

function process.signal(self, signum)
    self.handle:kill(self.pid, signum)
end

function process.kill(self)
    self:signal(9)
end

function process.get_pid(self)
    self.pid = uv.process_get_pid(self.handle)
    return self.pid
end

function process.run(self)
    if self.running then return self end

    self.handle, self.pid = uv.spawn(self.command, {
        args = self.args,
        stdio = {self.stdio_pipe, self.stdout_pipe, self.stderr_pipe},
        env = self.env,
        cwd = self.cwd,
        uid = self.uid,
        gid = self.gid,
        detached = self.detached,

    })
    self.running = true
    self.pid = self:get_pid()

    uv.read_start(self.stderr_pipe, self.on_stderr)
    uv.read_start(self.stdout_pipe, self.on_stdout)

    process.pid[self.pid] = self
end

function process.shutdown(self, callback)
    if self.shutdown then return end

    uv.shutdown(self.stdin_pipe, function()
        self.shutdown = true
        if callback then
            callback(self)
        end
    end)
end

function process.close(self, callback)
    if not self.running then
        return
    end

    uv.close(self.handle, function()
        self:shutdown()
        self.running = false

        if callback then
            callback(self)
        end
    end)
end

-- Waits until timeout if process has not exited
function process.show(self, opts)
    opts = opts or {}
    local make_buffer_and_split = vim.schedule_wrap(function(bufname, data)
        local command_str = self.command .. ' ' .. table.concat(self.args or {}, " ")
        local bufnr = vim.fn.bufadd(bufname)
        builtin.unshift(data, "", '  `' .. command_str .. '`', 'Compilation output for command:')
        data = table.concat(data, "\n")
        data = vim.split(data, "[\n]")

        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, data)

        opts.split = opts.split or 's'
        if opts.split == 's' then
            vim.cmd('split | wincmd j | b ' .. bufname)
        elseif opts.split == 'v' then
            vim.cmd('split | wincmd j | b ' .. bufname)
        elseif opts.split == 't' then
            vim.cmd('tabnew b ' .. bufname)
        end
    end)

    if not self.running then
        if not opts.stderr and not opts.stdout then
            opts.stderr = true
            opts.stdout = true
        end
        if opts.stderr and self.stderr and #self.stderr > 0 then
            make_buffer_and_split('compilation_stderr_pid_' .. self.pid, self.stderr)
        end
        if opts.stdout and self.stdout and #self.stdout > 0 then
            make_buffer_and_split('compilation_stdout_pid_' .. self.pid, self.stdout)
        end
    else
        if not uv.is_closing(self.handle) then
            self:close()
        end
    end
end

function process._init(self, command, opts)
    opts = opts or {}
    opts.stdin_pipe = opts.stdin or uv.new_pipe()
    opts.stderr_pipe = opts.stderr or uv.new_pipe()
    opts.stdout_pipe = opts.stdout or uv.new_pipe()
    opts.on_exit = opts.on_exit or process._on_exit(self)
    opts.on_stdout = opts.on_stdout or process._on_stdout(self)
    opts.on_stderr = opts.on_stderr or process._on_stderr(self)

    if types.is_type(command, 'table') then
        local l = #command
        if l > 1 then
            opts.args = builtin.slice(command, 2, #command) 
        end
        command = command[1]
    else
        command = vim.split(command, " ")
        local l = #command
        if l > 1 then
            opts.args = builtin.slice(command, 2, #command)
        end
        command = command[1]
    end
    opts.command = command

    opts.cwd = opts.cwd or path.currentdir()
    opts.env = opts.env or {
        HOME = os.getenv('HOME'),
        PATH = os.getenv('PATH'),
    }
    opts.detached = opts.detached or false
    opts.stdio = {opts.stdin_pipe, opts.stdout_pipe, opts.stderr_pipe}
    opts.running = false

    for k,v in pairs(opts) do
        self[k] = v
    end
end

p = Process('ls -lzjlsjdlkf kja;djfjadk')
p:run()

return builtin.process
