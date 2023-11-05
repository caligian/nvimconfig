require "core.utils.buffer"

terminal = struct("terminal", {
    'pid',
    "id",
    "cmd",
    "opts",
    "load_file",
    "on_input",
    "buffer",
})

terminal.terminals = terminal.terminals or {}

terminal.exceptions = {
    invalid_command = "expected valid command",
    shell_not_executable = "shell not executable",
    exited_with_error = "command exited with error",
    interrupted = "terminal interrupted",
    invalid_id = "invalid job id",
    no_default_command = 'no default command provided'
}

terminal.timeout = 200

function terminal.init(self, cmd, opts)
	opts = opts or {}

	validate {
		command = {'string', cmd},
		opts = {'table', opts}
	}

	opts = copy(opts)
	self.cmd = cmd
	self.load_file = opts.load_file
	self.on_input = opts.on_input
	opts.load_file = nil
	opts.on_input = nil
	self.opts = opts
	self.id = false
	self.pid = false
	self.buffer = false

	return self
end


function terminal.start(self, callback)
    if pid_exists(self.pid) then
        return self.id, self.pid
    end

    local scratch = buffer.create_empty()
    local cmd = self.cmd
    local id, term, pid

    buffer.call(scratch, function()
        opts = opts or self.opts or {}

        if is_empty(opts) then
            id = vim.fn.termopen(cmd)
        else
            id = vim.fn.termopen(cmd, opts)
        end

        local has_started = buffer.lines(scratch, 0, -1)
        has_started = filter(has_started, function (x) return #x ~= 0 end)

        while #has_started == 0 do
            vim.wait(10)
            has_started = buffer.lines(scratch, 0, -1)
            has_started = filter(has_started, function (x) return #x ~= 0 end)
        end

        term = buffer.bufnr()
        self.id = id
        pid = buffer.var(scratch, 'terminal_job_pid')
        self.pid = pid

		local ok = pid_exists(pid)
        if not ok then
            error('Could not run command successfully ' .. cmd)
        end

        buffer.map(scratch, "n", "q", ":hide<CR>", { name = "terminal.hide_buffer" })

        buffer.autocmd(term, {'BufWipeout'}, function ()
            terminal.stop(self)
            terminal.hide(self)
        end)

        if self.connected then
            buffer.autocmd(self.connected, {'BufWipeout'}, function ()
                terminal.stop(self)
            end)
        end

        if callback then
            callback(self)
        end
    end)

    self.buffer = term
    terminal.terminals[id] = self

    return id, pid
end

function terminal.get_status(self)
    return pid_exists(self.pid)
end

function terminal.is_running(self, success, failure)
    if pid_exists(self.pid) then
        if not buffer.exists(self.buffer) then
            kill_pid(self.pid)
            self.buffer = false
            return false
        end

        if success then
            return success(self)
        end

        return self
    end

	if failure then
		return failure(self)
	end
end

function terminal.unless_running(self, callback)
    return terminal.is_running(self, nil, callback)
end

function terminal.if_running(self, callback)
    return terminal.is_running(self, callback)
end

function terminal.center_float(self, opts)
    return terminal.float(self, merge({ center = { 0.8, 0.8 } }, opts or {}))
end

function terminal.dock(self, opts)
    return terminal.float(self, merge({ dock = 0.3 }, opts or {}))
end

function terminal.send_node_at_cursor(self, src_bufnr)
    src_bufnr = src_bufnr or vim.fn.bufnr()
    local pos = buffer.pos(src_bufnr)
    local line, col = pos.row, pos.col
    line = line - 1
    col = col - 1

    terminal.send(self, buffer.get_node_text_at_pos(src_bufnr, line, col))
end

function terminal.send_current_line(self, src_bufnr)
    if not terminal.is_running(self) then
        return
    end

    src_bufnr = src_bufnr or vim.fn.bufnr()
    return vim.api.nvim_buf_call(src_bufnr, function()
        local s = vim.fn.getline "."
        return terminal.send(self, s)
    end)
end

function terminal.send_buffer(self, src_bufnr)
    if not terminal.is_running(self) then
        return
    end

    src_bufnr = src_bufnr or vim.fn.bufnr()
    return terminal.send(self, vim.api.nvim_buf_get_lines(src_bufnr, 0, -1, false))
end

function terminal.send_till_cursor(self, src_bufnr)
    if not terminal.is_running(self) then
        return
    end

    src_bufnr = src_bufnr or vim.fn.bufnr()
    return buffer.call(src_bufnr, function()
        local line = vim.fn.line "."
        return terminal.send(self, vim.api.nvim_buf_get_lines(src_bufnr, 0, line, false))
    end)
end

function terminal.send_textsubject_at_cursor(self, src_bufnr)
    if not terminal.is_running(self) then
        return
    end

    src_bufnr = src_bufnr or buffer.bufnr()

    return terminal.send(
        self,
        buffer.call(src_bufnr, function()
            vim.cmd "normal! v."
            return buffer.range_text(src_bufnr)
        end)
    )
end

function terminal.send_range(self, src_bufnr)
    if not terminal.is_running(self) then
        return
    end

    src_bufnr = src_bufnr or vim.fn.bufnr()
    local out = buffer.range_text(src_bufnr)
    if not out then
        return false
    end

    return terminal.send(self, out)
end

function terminal.terminate_input(self)
    if not terminal.is_running(self) then
        return
    end
    return terminal.send(self, vim.api.nvim_replace_termcodes("<C-c>", true, false, true))
end

function terminal.send(self, s)
    if not terminal.is_running(self) then
        return
    end

    local id = self.id

    local function send_string(s)
        s = to_list(s)
        s[#s + 1] = ""

        vim.api.nvim_chan_send(id, table.concat(s, "\n"))

        buffer.call(self.buffer, function()
            vim.cmd "normal! G"
        end)
    end

    if is_a.string(s) then
        s = vim.split(s, "[\n\r]+")
    end

    if self.load_file then
        if self.on_input then
            s = self.on_input(s)
        end

        send_string(self.load_file("/tmp/nvim_repl_last_input", function(fname)
            file.write(fname, join(s, "\n"))
        end))
    elseif self.on_input then
        send_string(self.on_input(s))
    else
        send_string(s)
    end

    return true
end

function terminal.split(self, direction, opts)
    if not pid_exists(self.pid) then
        return
    end

    if not terminal.is_visible(self) then
        buffer.split(self.buffer, direction, opts)
    end
end

function terminal.float(self, opts)
    if not terminal.is_running(self) then
        return
    end

    if not terminal.is_visible(self) and self.buffer then
        return buffer.float(self.buffer, opts)
    end
end

function terminal.hide(self)
    if self.buffer then
        buffer.hide(self.buffer)
    end
end

function terminal.stop(self)
    terminal.hide(self)

    if not self.pid then
        return false
    elseif not terminal.is_running(self) then
        return false
    else
        kill_pid(self.pid, 9)

        self.pid = false
        self.id = false
    end

    return true
end

function terminal.stop_deprecated(self)
    if not terminal.is_running(self) then
        return
    end

    terminal.hide(self)
    vim.fn.chanclose(self.id)
    self.buffer = nil
    terminal.terminals[self.id] = false

    return self
end

function terminal.is_visible(self)
    if self.buffer then return buffer.is_visible(self.buffer) end
    return false
end

function terminal.stop_all()
    each(values(terminal.terminals), terminal.stop)
end

each({
    "vsplit",
    "tabnew",
 }, function (fun)
    terminal[fun] = function (self)
        return terminal.split(self, fun)
    end
end)
