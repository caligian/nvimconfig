require "core.utils.command-group"

local home = os.getenv "HOME"

buffer_group = {
    buffer_groups = {},
    buffers = {},
    command_group = command_group.new "BufferGroup",
}

function buffer_group.load_defaults(defaults)
    defaults = deepcopy(defaults or buffer_group.defaults)
    local event = defaults.event or "BufEnter"
    defaults.event = nil

    dict.each(defaults, function(name, spec)
        local pattern

        if is_a.string(spec) then
            pattern = spec
        else
            event = spec.event or event
            pattern = spec.pattern
        end

        buffer_group.new(name, event, pattern):enable()
    end)
end

buffer_group.add_command = function(name, callback, opts)
    local map = opts.map

    if map then
        local rest = map[3] or {}
        rest.name = name
        map[3] = rest
    end

    return buffer_group.command_group:add(name, callback, opts)
end

buffer_group.remove_command = function(name)
    return buffer_group.command_group:remove(name)
end

buffer_group.get_command = function(name)
    return buffer_group.command_group:get(name)
end

buffer_group.command_map = function(...)
    return buffer_group.command_group:map(...)
end

buffer_group.map_commands = function(commands)
    dict.each(
        commands or buffer_group.commands,
        function(name, spec) buffer_group.command_group:add(name, unpack(spec)) end
    )
end

function buffer_group.new(name, event, pattern)
    validate {
        name = { "string", name },
        pattern = { is { "array", "string" }, pattern },
        opt_event = { is { "array", "string" }, event },
    }

    local self = {
        name = name,
        event = array.to_array(event or "BufAdd"),
        pattern = array.to_array(pattern),
        autocmds = {},
        buffers = {},
        callbacks = {},
        exclude = {},
        is_valid_buffer = function(self, bufnr)
            bufnr = bufnr or buffer.bufnr()
            if not buffer.exists(bufnr) or self.exclude[bufnr] then
                return false
            end

            local name = buffer.name(bufnr)
            local found = false

            for i = 1, #self.pattern do
                found = name:match(self.pattern[i])
                if found then break end
            end

            return found
        end,
        exclude_buffer = function(self, ...)
            local success = {}
            array.each({ ... }, function(buf)
                buf = buffer.bufnr(buf)

                if not self.buffers[buf] then
                    return
                elseif self.exclude[buf] then
                    return
                end

                self.exclude[buf] = true
                self.buffers[buf] = nil

                array.append(success, buf)
            end)

            if #success == 0 then
                return nil, "invalid_buffer"
            else
                return success
            end
        end,
        remove_buffer = function(self, ...)
            local removed = {}
            array.each({ ... }, function(bufnr)
                bufnr = buffer.bufnr(bufnr)
                if not self.buffers[bufnr] then return end

                array.append(removed, bufnr)
                self.buffers[bufnr] = nil

                local exists, exists_t =
                    dict.get(buffer_group.buffers, { bufnr, self.name })

                if exists then exists_t[self.name] = nil end
                self.exclude[bufnr] = true
            end)

            if array.is_empty(removed) then
                return
            else
                return removed
            end
        end,
        buffer_exists = function(self, bufnr)
            return self.buffers[bufnr] or false
        end,
        prune = function(self)
            dict.each(self.buffers, function(bufnr, _)
                if not buffer.exists(bufnr) or self.exclude[bufnr] then
                    self.buffers[bufnr] = nil
                end
            end)

            local bufs = dict.keys(self.buffers)
            if dict.is_empty(bufs) then
                return
            else
                return bufs
            end
        end,
        add_buffer = function(self, ...)
            local added = {}
            array.each({ ... }, function(bufnr)
                if not self:is_valid_buffer(bufnr) or self.exclude[bufnr] then
                    return
                else
                    array.append(added, bufnr)
                end

                buffer_group.buffers[bufnr] = buffer_group.buffers[bufnr] or {}
                buffer_group.buffers[bufnr][self.name] = self
                self.buffers[bufnr] = true
            end)

            if #added == 0 then return nil, "invalid_buffer" end
            return added
        end,
        enable = function(self)
            local au_name = "buffer_group." .. self.name
            if
                self.autocmds[au_name] and self.autocmds[au_name]:is_enabled()
            then
                return self.autocmds[au_name]
            end

            local au = autocmd.map(self.event, {
                pattern = "*",
                callback = function() self:add_buffer(buffer.bufnr()) end,
                group = "buffer_group",
                name = self.name,
            })
            self.autocmds[au.name] = au

            return au
        end,
        list_buffers = function(self, callback)
            local bufs = self:prune()
            if not bufs then return end

            if callback then
                callback(self.buffers)
                return bufs
            else
                return bufs
            end
        end,
        run_picker = function(self, tp)
            local picker = self:create_picker(tp)
            if not picker then return end
            picker:find()
        end,
        include_buffer = function(self, ...)
            array.each({ ... }, function(buf)
                if not self.exclude[buf] then return end

                self.buffers[buf] = true
                self.exclude[buf] = nil
            end)
        end,
        get_excluded_buffers = function(self)
            local ks = dict.keys(self.exclude)
            if dict.is_empty(ks) then return end
            return ks
        end,
        create_picker = function(self, tp)
            local function create_include_buffer_picker()
                local bufs = self:get_excluded_buffers()
                if not bufs then return end

                local _ = telescope.load()
                local mod = {}

                function mod.include_buffer(prompt_bufnr)
                    self:include_buffer(
                        unpack(
                            array.map(
                                _:get_selected(prompt_bufnr),
                                function(buf) return buf.bufnr end
                            )
                        )
                    )
                end

                mod.default_action = mod.include_buffer
                local picker = _:create_picker({
                    results = bufs,
                    entry_maker = function(entry)
                        local bufname = buffer.name(entry)
                        return {
                            display = bufname,
                            value = entry,
                            ordinal = entry,
                            buffer_group = self.name,
                            bufnr = entry,
                            bufname = bufname,
                        }
                    end,
                }, {
                    mod.default_action,
                    { "n", "i", mod.include_buffer },
                }, {
                    prompt_title = "excluded buffers in buffer_group "
                        .. self.name,
                })

                return picker
            end

            local function create_picker(remove)
                local bufs = self:list_buffers()
                if not bufs then return end

                local items = {
                    results = bufs,
                    entry_maker = function(entry)
                        local bufname = buffer.name(entry)
                        return {
                            value = entry,
                            ordinal = entry,
                            buffer_group = self.name,
                            display = bufname,
                            bufname = bufname,
                            bufnr = entry,
                        }
                    end,
                }

                local _ = telescope.load()
                local mod = {}

                function mod.remove_buffer(prompt_bufnr)
                    local sel = _:get_selected(prompt_bufnr, true)
                    array.each(
                        sel,
                        function(buf) self:remove_buffer(buf.bufnr) end
                    )
                end

                function mod.open_buffer(prompt_bufnr)
                    local sel = _:get_selected(prompt_bufnr)[1]
                    if not sel then return end
                    buffer.open(sel.bufnr)
                end

                function mod.default_action(prompt_bufnr)
                    if remove then
                        mod.remove_buffer(prompt_bufnr)
                    else
                        mod.open_buffer(prompt_bufnr)
                    end
                end

                function mod.exclude_buffer(prompt_bufnr)
                    self:exclude_buffer(
                        unpack(
                            array.map(
                                _:get_selected(prompt_bufnr),
                                function(buf) return buf.bufnr end
                            )
                        )
                    )
                end

                local prompt_title
                if remove then
                    prompt_title = "remove buffers from buffer_group = "
                        .. self.name
                else
                    prompt_title = "buffer_group = " .. self.name
                end

                local picker = _:create_picker(items, {
                    mod.default_action,
                    { "n", "x", mod.remove_buffer },
                    { "n", "o", mod.open_buffer },
                }, {
                    prompt_title = prompt_title,
                })

                return picker
            end

            tp = tp or ""
            if tp:match "remove" then
                return create_picker(true)
            elseif tp:match "include" then
                return create_include_buffer_picker()
            else
                return create_picker()
            end
        end,
    }

    buffer_group.buffer_groups[name] = self
    return self
end

function buffer_group.create_picker(bufnr)
    bufnr = bufnr or buffer.bufnr()

    if not buffer.exists(bufnr) then return end

    local groups = buffer_group.buffers[bufnr]
    if not groups or dict.is_empty(groups) then return end

    items = dict.keys(groups)
    items = {
        results = items,
        entry_maker = function(entry)
            local bufname = buffer.name()
            return {
                buffer_group = entry,
                bufnr = bufnr,
                bufname = bufname,
                value = entry,
                display = sprintf(
                    "%-15s = %s :: %s",
                    entry,
                    array.join(groups[entry].event, ", "),
                    array.join(groups[entry].pattern, ", ")
                ),
                ordinal = bufnr,
            }
        end,
    }

    local mod = {}
    local _ = telescope.load()

    function mod.default_action(prompt_bufnr)
        local sel = _:get_selected(prompt_bufnr)[1]
        buffer_group.buffer_groups[sel.buffer_group]:run_picker()
    end

    function mod.remove_buffers(prompt_bufnr)
        local sel = _:get_selected(prompt_bufnr)[1]
        buffer_group.buffer_groups[sel.buffer_group]:run_picker "remove"
    end

    function mod.show_excluded_buffers(prompt_bufnr)
        local sel = _:get_selected(prompt_bufnr)[1]
        buffer_group.buffer_groups[sel.buffer_group]:run_picker "include"
    end

    function mod.change_pattern(prompt_bufnr)
        local sel = _:get_selected(prompt_bufnr)[1]
        local group = buffer_group.buffer_groups[sel.buffer_group]
        local pattern = group.pattern
        group.previous_pattern = pattern
        group.pattern =
            array.to_array(vim.split(vim.fn.input "new pattern % ", " *:: *"))
        printf(
            "pattern changed to  %s for buffer_group %s",
            dump(group.pattern),
            group.name
        )
    end

    return _:create_picker(items, {
        mod.default_action,
        { "n", "e", mod.show_excluded_buffers },
        { "n", "x", mod.remove_buffers },
        { "n", "p", mod.change_pattern },
    }, {
        prompt_title = "buffer_groups for buffer " .. buffer.name(bufnr),
    })
end

function buffer_group.is_excluded_buffer(bufnr)
    local found = array.grep(
        dict.values(buffer_group.buffer_groups),
        function(obj) return obj.exclude[bufnr] end
    )

    if #found == 0 then return false end

    return array.all(found)
end

function buffer_group.run_picker(bufnr)
    local picker = buffer_group.create_picker(bufnr)
    if picker then
        picker:find()
        return picker
    elseif buffer_group.is_excluded_buffer(bufnr) then
        printf("%s is excluded from all groups", buffer.name(bufnr))
    end
end

function buffer_group.get_statusline_string(bufnr)
    local state = buffer_group.buffers[bufnr]
    if not state or dict.is_empty(state) then return end

    return "<" .. array.join(dict.keys(state), " ") .. ">"
end

local function get_group(bufnr, group)
    group = buffer_group.buffers[bufnr]
    if not group then return nil, "buffer_not_captured" end

    group = group[group]
    if not group then return nil, "invalid_group" end

    return group
end

function buffer_group.add_buffer(bufnr, group)
    group, err = get_group(bufnr, group)
    if not group then return nil, err end

    return group:add_buffer(bufnr)
end

function buffer_group.remove_buffer(bufnr, group)
    group, err = get_group(bufnr, group)
    if not group then return nil, err end

    return group:remove_buffer(bufnr)
end

function buffer_group.exclude_buffer(bufnr, group)
    group, err = get_group(bufnr, group)
    if not group then return nil, err end

    return group:exclude_buffer(bufnr)
end

function buffer_group.get(name, callback)
    local group = buffer_group.buffer_groups[name]
    if not group then return end

    if callback then
        return callback(group)
    else
        return group
    end
end

function buffer_group.load_mappings(mappings)
    mappings = mappings or buffer_group.mappings

    if not mappings then return end

    local out = {}
    local opts = mappings.opts

    dict.each(mappings, function(name, spec)
        if name == "opts" then return end

        if opts then
            local mode, ks, cb, rest
            ks, cb, rest = unpack(spec)
            rest = dict.merge(rest or {}, opts)
            rest.name = "buffer_group." .. name
            mode = rest.mode or "n"
            spec = { mode, ks, cb, rest }

            apply(kbd.map, spec)
        else
            spec = deepcopy(spec)
            local mode, ks, cb, rest = unpack(spec)
            rest = rest or {}
            rest.name = "buffer_group." .. name
            spec[4] = rest

            apply(kbd.map, spec)
        end
    end)
end
