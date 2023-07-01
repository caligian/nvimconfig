require "core.utils.terminal"

repl = {
    repls = {},
    exception = {
        no_command = exception 'no command provided'
    },
}

function repl.new(ft, default_cmd)
    ft = ft or vim.bo.filetype
    if #ft == 0 then return end

    local already_exists = repl.repls[ft]
    if already_exists then return already_exists end

    local defaults = filetype.get(ft, 'repl')
    local on_input
    if defaults then
        if is_a.string(defaults) then defaults = {defaults} end
        local cmd = defaults[1]
        on_input = defaults.on_input
        if not default_cmd then default_cmd = cmd end
    end

    repl.repls[ft] = {
        cmd = default_cmd,
        on_input = on_input,
        ft = ft,
        buffers = {},
        single_instance = false,
        terminals = {},
        start_single = function(self, cmd, opts)
            if self.single_instance and self.single_instance:is_running() then
                return self.single_instance
            end

            cmd = cmd or self.cmd
            local term = terminal.new(cmd, opts)
            self.single_instance = term

            return term:start()
        end,
        start = function(self, cmd, opts)
            local bufnr = buffer.bufnr() or opts.bufnr
            local exists = self.buffers[bufnr]
            if exists and exists:is_running() then return exists end

            if not cmd and not self.default_cmd then
                cmd = filetype.get(self.ft, "repl")

                if not cmd then
                    return
                elseif is_a.table(cmd) then
                    local tmp = cmd
                    cmd = tmp[1]

                    if not opts then
                        opts = tmp
                    elseif tmp.config then
                        opts = dict.merge(deepcopy(opts), tmp.config)
                    end
                end
            end

            opts = opts or {}
            local term = terminal.new(cmd, opts)
            term:start()
            self.buffers[bufnr] = term
            self.terminals[cmd] = term

            return term
        end,
        if_running = function(self, cmd, callback)
            if not self.terminals[cmd] then return end
            return self.terminals[cmd]:if_running(callback)
        end,
        if_single_running = function (self, callback)
            return self.single_instance:if_running(callback)
        end,
        single_split = function (self, direction, opts)
            direction = direction or 'split'
            return self:if_single_running(function ()
                return self.single_instance:split(direction, opts)
            end)
        end,
        single_vsplit = function (self, opts)
            return self:if_single_running(function ()
                return self.single_instance:split('vert', opts)
            end)
        end,
        single_tabnew = function (self, opts)
            return self:if_single_running(function ()
                return self.single_instance:split('tabnew', opts)
            end)
        end,
        single_botright = function (self, opts)
            return self:if_single_running(function ()
                return self.single_instance:split('botright', opts)
            end)
        end,
        single_topleft = function (self, opts)
            return self:if_single_running(function ()
                return self.single_instance:split('topleft', opts)
            end)
        end,
        single_aboveleft = function (self, opts)
            return self:if_single_running(function ()
                return self.single_instance:split('aboveleft', opts)
            end)
        end,
        single_belowright = function (self, opts)
            return self:if_single_running(function ()
                return self.single_instance:split('belowright', opts)
            end)
        end,
        single_rightbelow = function (self, opts)
            return self:if_single_running(function ()
                return self.single_instance:split('rightbelow', opts)
            end)
        end,
        single_leftabove = function (self, opts)
            return self:if_single_running(function ()
                return self.single_instance:split('leftabove', opts)
            end)
        end,
        split = function (self, cmd, direction, opts)
            direction = direction or 'split'
            return self:if_running(cmd, function ()
                return self.terminals[cmd]:split(direction, opts)
            end)
        end,
        vsplit = function (self, cmd, opts)
            return self:if_running(cmd, function ()
                return self.terminals[cmd]:split('vert', opts)
            end)
        end,
        tabnew = function (self, cmd, opts)
            return self:if_running(cmd, function ()
                return self.terminals[cmd]:split('tab', opts)
            end)
        end,
        botright = function (self, cmd, opts)
            return self:if_running(cmd, function ()
                return self.terminals[cmd]:split('botright', opts)
            end)
        end,
        topleft = function (self, cmd, opts)
            return self:if_running(cmd, function ()
                return self.terminals[cmd]:split('topleft', opts)
            end)
        end,
        aboveleft = function (self, cmd, opts)
            return self:if_running(cmd, function ()
                return self.terminals[cmd]:split('aboveleft', opts)
            end)
        end,
        belowright = function (self, cmd, opts)
            return self:if_running(cmd, function ()
                return self.terminals[cmd]:split('belowright', opts)
            end)
        end,
        rightbelow = function (self, cmd, opts)
            return self:if_running(cmd, function ()
                return self.terminals[cmd]:split('rightbelow', opts)
            end)
        end,
        leftabove = function (self, cmd, opts)
            return self:if_running(cmd, function ()
                return self.terminals[cmd]:split('leftabove', opts)
            end)
        end,
        send = function(self, cmd, s, formatter)
            return self:if_running(cmd, function ()
                validate.string(is {'table', 'string'}, s)
                s = is_a.string(s) and vim.split(s, "\n") or s
                if formatter then s = formatter(s) end

                return self.terminals[cmd]:send(s)
            end)
        end,
        send_buffer = function(self, cmd, bufnr)
            return self:if_running(cmd, function ()
                self.terminals[cmd]:send_buffer(bufnr)
            end)
        end,
        send_node_at_cursor = function(self, cmd, bufnr)
            return self:if_running(cmd, function ()
                self.terminals[cmd]:send_node_at_cursor(bufnr)
            end)
        end,
        send_current_line = function(self, cmd, bufnr)
            return self:if_running(cmd, function ()
                self.terminals[cmd]:send_current_line(bufnr)
            end)
        end,
        send_textsubject_at_cursor = function(self, cmd, bufnr)
            return self:if_running(cmd, function ()
                self.terminals[cmd]:send_textsubject_at_cursor(bufnr)
            end)
        end,
        send_till_cursor = function(self, cmd, bufnr)
            return self:if_running(cmd, function ()
                self.terminals[cmd]:send_till_cursor(bufnr)
            end)
        end,
        single_send = function (self, s, formatter)
            if not self.single_instance then return end

            return self.single_instance:if_running(function ()
                validate.string(is {'table', 'string'}, s)
                s = is_a.string(s) and vim.split(s, "\n") or s
                if formatter then s = formatter(s) end

                return self.single_instance:send(s)
            end)
        end,
        single_send_buffer = function (self, bufnr)
            return self:if_running(function ()
                self.single_instance:send_buffer(bufnr)
            end)
        end,
        single_send_node_at_cursor = function (self, bufnr)
            return self:if_running(function ()
                self.single_instance:send_node_at_cursor(bufnr)
            end)
        end,
        single_send_current_line = function (self, bufnr)
            return self:if_running(function ()
                self.single_instance:send_current_line(bufnr)
            end)
        end,
        single_send_textsubject_at_cursor = function (self, bufnr)
            return self:if_running(function ()
                self.single_instance:send_textsubject_at_cursor(bufnr)
            end)
        end,
        single_send_till_cursor = function (self, bufnr)
            return self:if_running(function ()
                self.single_instance:send_till_cursor(bufnr)
            end)
        end,
        stop = function(self, cmd)
            if not cmd then
                if self.single_instance then
                    return self.single_instance:stop()
                end
            elseif self.terminals[cmd] then
                return self.terminals[cmd]:stop()
            end
        end,
        stop_all = function(self)
            local single_running = self.single_instance:is_running()
            if single_running then self.single_instance:stop() end

            dict.each(self.terminals, function(_, obj) obj:stop() end)

            self.single_instance = false
            self.terminals = false

            return self
        end,
        unless_running = function(self, cmd, callback)
            if is_a.callable(cmd) then
                return self.single_instance:if_running(callback)
            elseif not self.terminals[cmd] then
                return
            else
                self.terminals[cmd]:if_running(callback)
            end
        end,
    }

    return repl.repls[ft]
end

function repl.get(ft, callback)
    opts = opts or {}

    if not repl.repls[ft] then
        return
    elseif callback then
        return callback(repl.repls[ft])
    else
        return repl.repls[ft]
    end
end

function repl.if_single_running(ft, callback)
    local obj = repl.repls[ft]
    local should_return = not obj or not obj.single_instance or not obj.single_instance:is_running()
    if should_return then return end

    return callback(obj, obj.single_instance)
end

function repl.if_running(ft, cmd, callback)
    local obj = repl.repls[ft]
    local should_return = not obj or not obj.terminals[cmd] or not obj.terminals[cmd]:is_running()
    if should_return then return end

    return callback(obj, obj.terminals[cmd])
end

function repl.action(ft, cmd, action, ...)
    local args = {...}
    local single = repl.get(ft)
    local should_return = not single or not single.terminals[cmd] or not single[action]
    if should_return then return end

    return repl.if_running(ft, cmd, function (repl_obj, _)
        return repl_obj[action](repl_obj, cmd, unpack(args))
    end)
end

function repl.single_action(ft, action, ...)
    local args = {...}
    local single = repl.get(ft)

    if not single then return end
    if not single[action] then return end

    return repl.if_single_running(ft, function (repl_obj, _)
        return repl_obj[action](repl_obj, unpack(args))
    end)
end
