require "core.utils.buffer"

terminal = terminal
    or {
        terminals = {},
        timeout = 30,
        exception = {
            invalid_command = exception "expected valid command",
            shell_not_executable = exception "shell not executable",
            exited_with_error = exception "command exited with error",
            interrupted = exception "terminal interrupted",
            invalid_id = exception "invalid job id",
        },
    }

function terminal.new(cmd, opts)
    opts = vim.deepcopy(opts or {})

    validate {
        cmd = { "string", cmd },
        opts = { "table", opts },
    }

    local on_input = opts.on_input
    opts.on_input = nil

    return {
        id = false,
        cmd = cmd,
        opts = opts,
        on_input = on_input or false,
        center_float = function(self, opts)
            return self:float(dict.merge({ center = { 0.8, 0.8 } }, opts or {}))
        end,
        dock = function(self, opts)
            return self:float(dict.merge({ dock = 0.3 }, opts or {}))
        end,
        send_node_at_cursor = function(self, src_bufnr)
            src_bufnr = src_bufnr or vim.fn.bufnr()
            local pos = buffer.pos(src_bufnr)
            local line, col = pos.row, pos.col
            line = line - 1
            col = col - 1

            self:send(buffer.get_node_text_at_pos(src_bufnr, line, col))
        end,
        send_current_line = function(self, src_bufnr)
            if not self:is_running() then
                return
            end

            src_bufnr = src_bufnr or vim.fn.bufnr()
            return vim.api.nvim_buf_call(src_bufnr, function()
                local s = vim.fn.getline "."
                return self:send(s)
            end)
        end,
        send_buffer = function(self, src_bufnr)
            if not self:is_running() then
                return
            end

            src_bufnr = src_bufnr or vim.fn.bufnr()
            return self:send(vim.api.nvim_buf_get_lines(src_bufnr, 0, -1, false))
        end,
        send_till_cursor = function(self, src_bufnr)
            if not self:is_running() then
                return
            end

            src_bufnr = src_bufnr or vim.fn.bufnr()
            return buffer.call(src_bufnr, function()
                local line = vim.fn.line "."
                return self:send(vim.api.nvim_buf_get_lines(src_bufnr, 0, line, false))
            end)
        end,
        send_textsubject_at_cursor = function(self, src_bufnr)
            if not self:is_running() then
                return
            end

            src_bufnr = src_bufnr or buffer.bufnr()

            return self:send(buffer.call(src_bufnr, function()
                vim.cmd "normal! v."
                return buffer.range_text(src_bufnr)
            end))
        end,
        send_range = function(self, src_bufnr)
            if not self:is_running() then return end

            src_bufnr = src_bufnr or vim.fn.bufnr()
            local out = buffer.range_text(src_bufnr)
            if not out then return false end

            return self:send(out)
        end,
        terminate_input = function(self)
            if not self:is_running() then
                return
            end
            return self:send(vim.api.nvim_replace_termcodes("<C-c>", true, false, true))
        end,
        send = function(self, s)
            if not self:is_running() then
                return
            end

            local id = self.id
            if is_a.string(s) then
                s = vim.split(s, "[\n\r]+")
            end

            if self.on_input then s = self.on_input(s) end
            s[#s + 1] = ""

            vim.api.nvim_chan_send(id, table.concat(s, "\n"))

            buffer.call(self.bufnr, function()
                vim.cmd "normal! G"
            end)

            return true
        end,
        split = function(self, direction, opts)
            if not self:is_running() then
                return
            end
            if not self:is_visible() then
                buffer.split(self.bufnr, direction, opts)
            end
        end,
        float = function(self, opts)
            if not self:is_running() then
                return
            end
            if not self:is_visible() and self.bufnr then
                return buffer.float(self.bufnr, opts)
            end
        end,
        hide = function(self)
            if self.bufnr then
                buffer.hide(self.bufnr)
            end
        end,
        stop = function(self)
            if not self:is_running() then
                return
            end

            self:hide()
            vim.fn.chanclose(self.id)
            self.bufnr = nil
            terminal.terminals[self.id] = false

            return self
        end,
        is_visible = function(self)
            if self.bufnr then
                return buffer.is_visible(self.bufnr)
            end
            return false
        end,
        start = function(self, callback, opts)
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

                local ok, ex = self:get_status(opts.timeout or terminal.timeout)
                term = buffer.bufnr()
                if not ok and ex then
                    error(ex)
                end

                buffer.map(scratch, "n", "q", ":hide<CR>", { name = "terminal.hide_buffer" })

                if callback then
                    callback(self)
                end
            end)

            self.bufnr = term
            terminal.terminals[id] = self

            return id
        end,
        get_status = function(self, timeout)
            if not self.id then
                return
            end

            local id = self.id

            if id == 0 then
                return false, "invalid_command"
            elseif id == -1 then
                return false, "shell_not_executable"
            end

            local status = vim.fn.jobwait({ id }, timeout or terminal.timeout)[1]

            if status ~= -1 and status ~= 0 then
                if status >= 126 then
                    return false, "invalid_command"
                elseif status == -2 then
                    return false, "interrupted"
                elseif status == -3 then
                    return false, "invalid_id"
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
        unless_running = function()
            if self:is_running() then
                return
            end
            return callback(self)
        end,
    }
end

function terminal.stop_all()
    dict.each(terminal.terminals, function(_, obj)
        if obj:is_running() then
            obj:stop()
        end
    end)
end
