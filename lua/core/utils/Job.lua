#!/usr/bin/luajit

local uv = vim.loop

Job = struct("Job", {
    "exit_code",
    "cmd",
    "args",
    "pipes",
    "lines",
    "errors",
    "handle",
    "check",
    "tty",
    "stdout_buffer",
    "stderr_buffer",
})

function Job.mkpipes(self)
    self.pipes = {}
    local stdout, stderr, stdin

    stdout = uv.new_pipe()
    stderr = uv.new_pipe()
    stdin = uv.new_pipe()

    self.pipes.stdout = stdout
    self.pipes.stderr = stderr
    self.pipes.stdin = stdin
end

function Job.opts(self, opts)
    opts = opts or {}
    self.pipes = self.pipes or {}

    return merge(opts, {
        args = self.args,
        stdio = { self.pipes.stdin, self.pipes.stdout, self.pipes.stderr },
    })
end

function Job.init_before(cmd, opts)
    opts = copy(opts or {})
    local self = {}
    args = args or {}
    local check = uv.new_check()
    local stdout = opts.stdout
    local stderr = opts.stderr
    local output = opts.output
    local split = opts.split
    local out_buf = split and buffer.create_empty()

    if is_table(cmd) then
        args = array.slice(cmd, 2, -1)
        cmd = cmd[1]
    end

    if out_buf then
        buffer.set_option(out_buf, { buftype = "nofile", buflisted = false })
        buffer.map(out_buf, "n", "q", ":hide <CR>")
        output = true
    end

    Job.mkpipes(self)
    Job.opts(self, opts)

    local fh = uv.spawn(
        cmd,
        opts,
        vim.schedule_wrap(function(code, _)
            check:stop()
            self.exit_code = code
            Job.close(self)

            if split then
                local lines = {"COMMAND: " .. cmd, "---"}
                local no_lines = #self.lines == 0 or #self.lines == 0 and #self.lines[1] == 0
                local no_errors = #self.errors == 0 or #self.errors == 0 and #self.errors[1] == 0

                if not no_lines then
                    extend(lines, "STDOUT", "\n", self.lines)
                end

                if not no_errors then
                    extend(lines, "STDERR", "\n", self.errors)
                end

                buffer.set_lines(out_buf, 0, -1, lines)
                buffer.split(out_buf, not is_string(split) and "s" or split)
                buffer.call(out_buf, function()
                    vim.cmd "resize 15"
                end)
            end
        end)
    )

    if not fh then
        error("could not run command: " .. cmd)
    end

    check:start(function()
        if Job.is_closing(self, true) then
            Job.close(self)
        end
    end)

    self.args = args
    self.cmd = cmd
    self.check = check
    self.handle = fh
    self.lines = {}
    self.errors = {}
    self.args = args

    if output then
        if is_callable(output) then
            stdout = output
            stderr = output
        else
            stdout = true
            stderr = true
        end
    end

    if stdout or stderr then
        local function collect(err, data, tp)
            if err then
                extend(self.errors, err)
            elseif data then
                data = data:split "\n"
                extend(self.lines, data)
            end

            if tp == "stdout" and is_callable(stdout) then
                stdout(self.lines)
            elseif tp == "stderr" and is_callable(stderr) then
                stderr(self.lines)
            end
        end

        if stdout then
            uv.read_start(self.pipes.stdout, function(err, data)
                collect(err, data, "stdout")
            end)
        end

        if stderr then
            uv.read_start(self.pipes.stdout, function(err, data)
                collect(err, data, "stderr")
            end)
        end
    end

    return self
end

function Job.wait(self, timeout, tries, inc)
    if self.exit_code then
        return true
    elseif not self.handle or not uv.is_active(self.handle) then
        return false
    end

    timeout = timeout or 50
    tries = tries or 10
    inc = inc or timeout / 5
    local i = 0

    while i <= tries do
        if self.exit_code then
            break
        elseif uv.is_closing(self.handle) then
            break
        elseif Job.is_closing(self, "stdout") or Job.is_closing(self, "stderr") then
            break
        end

        vim.wait(timeout)

        timeout = timeout + inc
        i = i + 1
        inc = timeout / 10
    end

    return self.exit_code ~= nil
end

function Job.wait_for_output(self, timeout, tries, inc)
    if Job.wait(self, timeout, tries, inc) then
        return { stdout = self.lines, stderr = self.errors }
    end

    return false
end

function Job.close(self)
    if self.handle:is_closing() then
        return
    end

    self.pipes.stdout:shutdown()
    self.pipes.stderr:shutdown()
    self.handle:close()

    return self
end

function Job.is_active(self)
    if not self.handle then
        return false
    elseif not uv.is_active(self.handle) then
        return false
    end

    return true
end

function Job.is_closing(self, pipes)
    if not self.handle then
        return false
    elseif pipes == true then
        return self.pipes.stdin and uv.is_closing(self.pipes.stdin),
            self.pipes.stdout and uv.is_closing(self.pipes.stdout),
            self.pipes.stderr and uv.is_closing(self.pipes.stderr)
    elseif pipes == "stdout" then
        return self.pipes.stdout and uv.is_closing(self.pipes.stdout)
    elseif types == "stdin" then
        return self.pipes.stdin and uv.is_closing(self.pipes.stdin)
    elseif types == "stderr" then
        return self.pipes.stderr and uv.is_closing(self.pipes.stderr)
    else
        return uv.is_closing(self.handle)
    end
end

function Job.close_stderr_pipe(self)
    if self.pipes.stderr and not uv.is_closing(self.pipes.stderr) then
        self.pipes.stderr:shutdown()
        return true
    end

    return false
end

function Job.close_stdin_pipe(self)
    if self.pipes.stdin and not uv.is_closing(self.pipes.stdin) then
        self.pipes.stdin:shutdown()
        return true
    end

    return false
end

function Job.close_stdout_pipe(self)
    if self.pipes.stdout and not uv.is_closing(self.pipes.stdout) then
        self.pipes.stdout:shutdown()
        return true
    end

    return false
end

function Job.close_pipes(self)
    return Job.close_stdout_pipe(self), Job.close_stderr_pipe(self), Job.close_stdin_pipe(self)
end

function Job.send(self, s)
    if not self.handle or not uv.is_active(self.handle) then
        return false
    elseif Job.is_closing(self, "stdin") then
        return false
    end

    return uv.write(self.pipes.stdin, s:split "\n")
end

j = Job("ls", { stdout = true, split = "botright split" })


return Job
