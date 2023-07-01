command_group = {command_groups = {}}

local function validate_name(s)
    local ok = s:match '^[a-zA-Z][a-zA-Z0-9]+$'
    if not ok then return nil, 'invalid_name' end

    return s:gsub('^([a-z])', string.upper)
end

local function create_name(group, s)
    local ok, err = validate_name(s)
    if not s then return ok, err end 

    return group .. ok
end

function command_group.new(group_name)
    local exists = command_group.command_groups[group_name]
    return exists or {
        name = validate_name(group_name),
        commands = {},
        mappings = {},
        add = function (self, name, callback, opts)
            opts = deepcopy(opts or {nargs=0})
            name = create_name(self.name, name)
            local map = opts.map
            opts.map = nil

            if is_a.string(callback) then
                local current = callback
                callback = function () vim.cmd(current) end
            end

            vim.api.nvim_create_user_command(name, callback, opts)
            local cmd = { name = name, callback = callback, opts = opts }
            self.commands[name] = cmd

            if not map then return cmd end

            local rest = deepcopy(map[3] or {})
            rest.name = name
            map[3] = rest

            return cmd, self:map(name, unpack(map))
        end,
        remove = function (self, name)
            name = create_name(name)
            local cmd = self.commands[name] 
            if not cmd then return end
            self.commands[name] = nil

            return cmd
        end,
        list = function (self)
            local ks = dict.keys(self.commands)
            return #ks == 0 and nil or ks
        end,
        get_command = function (self, cmd)
            local exists = self.commands[cmd]
            if exists then return exists end

            cmd = create_name(self.name, cmd)
            return self.commands[cmd]

        end,
        map = function (self, cmd, mode, ks, opts)
            local cb = self:get_command(cmd)
            if not cb then return end

            cb = cb.callback
            opts = deepcopy(opts or {})
            opts.name = 'command.' .. opts.name .. '.' .. opts.name
            self.mappings[opts.name] = kbd.map(mode, ks, cb, opts)

            return self.mappings[opts.name]
        end,
    }
end

function command_group.map(spec)
    dict.each(spec, function (name, command)
        local group = command_group.new(name)
        dict.each(command, function (command_name, command_spec)
            local callback = command_spec.callback
            local opts = command_spec.opts
            local cmd = group:add(command_name, callback, opts)
            local mappings = command_spec.mappings

            if not mappings then return end

            local mappings = deepcopy(command_spec.mappings)
            local opts = mappings.opts
            mappings.opts = nil

            if opts then
                dict.each(mappings, function (kbd_name, kbd_spec)
                    local _opts = kbd_spec[2] or {}
                    _opts = dict.merge(deepcopy(_opts), opts)
                    _opts.mode = _opts.mode or 'n'
                    _opts.name = kbd_name
                    kbd_spec[2] = _opts
                end)
            else
                dict.each(mappings, function (kbd_name, kbd_spec)
                    local _opts = deepcopy(kbd_spec[2] or {})
                    _opts.mode = _opts.mode or 'n'
                    _opts.name = kbd_name
                    kbd_spec[3] = _opts
                    group:map(cmd.name, unpack(kbd_spec))
                end)
            end
        end)
    end)
end
