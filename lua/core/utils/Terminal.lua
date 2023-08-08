require "core.utils.buffer"

Terminal =  struct.new("Terminal", {
        "id",
        "cmd",
        "opts",
        "load_file",
        "on_input",
        "bufnr",
    })

Terminal.terminals = Terminal.terminals or {}

Terminal.exception = {
    invalid_command = exception "expected valid command",
    shell_not_executable = exception "shell not executable",
    exited_with_error = exception "command exited with error",
    interrupted = exception "terminal interrupted",
    invalid_id = exception "invalid job id",
}

Terminal.timeout = 100

function Terminal.init_before(cmd, opts)
    opts = copy(opts or {})
    local load_file, on_input = opts.load_file, opts.on_input
    opts.load_file = nil
    opts.on_input = nil

    return { cmd = cmd, opts = opts, on_input = on_input, load_file = load_file, id = false }
end

function Terminal.start(self, callback)
    local scratch = buffer.create_empty()
    local id, term

    buffer.call(scratch, function()
        opts = opts or self.opts or {}

        if dict.is_empty(opts) then
            id = vim.fn.termopen(self.cmd)
        else
            id = vim.fn.termopen(self.cmd, opts)
        end

        self.id = id

        local ok, ex = Terminal.get_status(self, opts.timeout or Terminal.timeout)
        term = buffer.bufnr()
        if not ok and ex then
            exception.throw(Terminal.exception[ex], self)
        end

        buffer.map(scratch, "n", "q", ":hide<CR>", { name = "terminal.hide_buffer" })

        if callback then
            callback(self)
        end
    end)

    self.bufnr = term
    Terminal.terminals[id] = self

    return id
end

function Terminal.get_status(self, timeout, success)
    if not self.id then
        return
    end

    local id = self.id

    if id == 0 then
        return false, "invalid_command"
    elseif id == -1 then
        return false, "shell_not_executable"
    end

    local status = vim.fn.jobwait({ id }, timeout or Terminal.timeout)[1]

    if status ~= -1 and status ~= 0 then
        if status >= 126 then
            return false, "invalid_command"
        elseif status == -2 then
            return false, "interrupted"
        elseif status == -3 then
            return false, "invalid_id"
        end
    end

    if success then
        success(self)
    end

    return id
end

function Terminal.is_running(self, success)
    return Terminal.get_status(self, nil, success)
end

function Terminal.if_running(self, callback)
    return Terminal.is_running(self, callback)
end

function Terminal.center_float(self, opts)
    return Terminal.float(self, dict.merge({ center = { 0.8, 0.8 } }, opts or {}))
end

function Terminal.dock(self, opts)
    return Terminal.float(self, dict.merge({ dock = 0.3 }, opts or {}))
end

function Terminal.send_node_at_cursor(self, src_bufnr)
    src_bufnr = src_bufnr or vim.fn.bufnr()
    local pos = buffer.pos(src_bufnr)
    local line, col = pos.row, pos.col
    line = line - 1
    col = col - 1

    Terminal.send(self, buffer.get_node_text_at_pos(src_bufnr, line, col))
end

function Terminal.send_current_line(self, src_bufnr)
    if not Terminal.is_running(self) then
        return
    end

    src_bufnr = src_bufnr or vim.fn.bufnr()
    return vim.api.nvim_buf_call(src_bufnr, function()
        local s = vim.fn.getline "."
        return Terminal.send(self, s)
    end)
end

function Terminal.send_buffer(self, src_bufnr)
    if not Terminal.is_running(self) then
        return
    end

    src_bufnr = src_bufnr or vim.fn.bufnr()
    return Terminal.send(self, vim.api.nvim_buf_get_lines(src_bufnr, 0, -1, false))
end
function Terminal.send_till_cursor(self, src_bufnr)
    if not Terminal.is_running(self) then
        return
    end

    src_bufnr = src_bufnr or vim.fn.bufnr()
    return buffer.call(src_bufnr, function()
        local line = vim.fn.line "."
        return Terminal.send(self, vim.api.nvim_buf_get_lines(src_bufnr, 0, line, false))
    end)
end

function Terminal.send_textsubject_at_cursor(self, src_bufnr)
    if not Terminal.is_running(self) then
        return
    end

    src_bufnr = src_bufnr or buffer.bufnr()

    return Terminal.send(
        self,
        buffer.call(src_bufnr, function()
            vim.cmd "normal! v."
            return buffer.range_text(src_bufnr)
        end)
    )
end

function Terminal.send_range(self, src_bufnr)
    if not Terminal.is_running(self) then
        return
    end

    src_bufnr = src_bufnr or vim.fn.bufnr()
    local out = buffer.range_text(src_bufnr)
    if not out then
        return false
    end

    return Terminal.send(self, out)
end

function Terminal.terminate_input(self)
    if not Terminal.is_running(self) then
        return
    end
    return Terminal.send(self, vim.api.nvim_replace_termcodes("<C-c>", true, false, true))
end

function Terminal.send(self, s)
    if not Terminal.is_running(self) then
        return
    end

    local id = self.id

    local function send_string(s)
        s = to_array(s)
        s[#s + 1] = ""

        vim.api.nvim_chan_send(id, table.concat(s, "\n"))

        buffer.call(self.bufnr, function()
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
            file.write(fname, array.join(s, "\n"))
        end))
    elseif self.on_input then
        send_string(self.on_input(s))
    else
        send_string(s)
    end

    return true
end

function Terminal.split(self, direction, opts)
    if not Terminal.is_running(self) then
        return
    end

    if not Terminal.is_visible(self) then
        buffer.split(self.bufnr, direction, opts)
    end
end

function Terminal.float(self, opts)
    if not Terminal.is_running(self) then
        return
    end
    if not Terminal.is_visible(self) and self.bufnr then
        return buffer.float(self.bufnr, opts)
    end
end

function Terminal.hide(self)
    if self.bufnr then
        buffer.hide(self.bufnr)
    end
end

function Terminal.stop(self)
    if not Terminal.is_running(self) then
        return
    end

    Terminal.hide(self)
    vim.fn.chanclose(self.id)
    self.bufnr = nil
    Terminal.terminals[self.id] = false

    return self
end

function Terminal.is_visible(self)
    if self.bufnr then return buffer.is_visible(self.bufnr) end
    return false
end

function Terminal.stop_all()
    array.each(values(Terminal.terminals), Terminal.stop)
end

array.each({
    "vsplit",
    "tabnew",
    "botright",
    "belowright",
    "rightbelow",
    "leftabove",
    "aboveleft",
}, function (fun)
    Terminal[fun] = function (self)
        return Terminal.split(self, fun)
    end
end)
