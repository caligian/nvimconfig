BufferGroup = BufferGroup or struct("BufferGroup", { "buffers", "name", "event", "pattern", "callbacks", "exclude", "autocmd" })

BufferGroup.buffers = BufferGroup.buffers or {}
BufferGroup.BufferGroups = BufferGroup.BufferGroups or {}
BufferGroup.mappings = {}
BufferGroup.autocmds = {}

function BufferGroup.init_before(name, event, pattern)
    validate {
        name = { "string", name },
        pattern = { union("array", "string"), pattern },
        opt_event = { union("array", "string"), event },
    }

    return {
        name = name,
        event = array.to_array(event or "BufEnter"),
        pattern = array.to_array(pattern),
        callbacks = {},
        exclude = {},
        buffers = {},
        autocmd = false,
    }
end

function BufferGroup.init(self)
    BufferGroup.BufferGroups[self.name] = self
    return self
end

function BufferGroup.is_valid_buffer(self, bufnr)
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
end

function BufferGroup.exclude_buffer(self, ...)
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
end

function BufferGroup.remove_buffer(self, ...)
    local removed = {}
    array.each({ ... }, function(bufnr)
        bufnr = buffer.bufnr(bufnr)
        if not self.buffers[bufnr] then
            return
        end

        array.append(removed, bufnr)
        self.buffers[bufnr] = nil

        local exists, exists_t = dict.get(BufferGroup.buffers, { bufnr, self.name })

        if exists then
            exists_t[self.name] = nil
        end
        self.exclude[bufnr] = true
    end)

    if array.is_empty(removed) then
        return
    else
        return removed
    end
end

function BufferGroup.buffer_exists(self, bufnr)
    return self.buffers[bufnr] or false
end

function BufferGroup.prune(self)
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
end

function BufferGroup.add_buffer(self, ...)
    local added = {}
    array.each({ ... }, function(bufnr)
        if not BufferGroup.is_valid_buffer(self, bufnr) or self.exclude[bufnr] then
            return
        else
            array.append(added, bufnr)
        end

        BufferGroup.buffers[bufnr] = BufferGroup.buffers[bufnr] or {}
        BufferGroup.buffers[bufnr][self.name] = self
        self.buffers[bufnr] = true
    end)

    if #added == 0 then
        return nil, "invalid_buffer"
    end
    return added
end

function BufferGroup.enable(self)
    if self.autocmd then
        return self.autocmd
    end

    local au = autocmd.map(self.event, {
        pattern = "*",
        callback = function()
            BufferGroup.add_buffer(self, buffer.bufnr())
        end,
        group = "BufferGroup",
        name = self.name,
    })

    self.autocmd = au

    return au
end

function BufferGroup.list_buffers(self, callback)
    local bufs = BufferGroup.prune(self)
    if not bufs then
        return
    end

    if callback then
        callback(self.buffers)
        return bufs
    else
        return bufs
    end
end

function BufferGroup.run_picker(self, tp)
    local picker = BufferGroup.create_picker(self, tp)
    if not picker then
        return
    end
    picker:find()
end

function BufferGroup.include_buffer(self, ...)
    array.each({ ... }, function(buf)
        if not self.exclude[buf] then
            return
        end

        self.buffers[buf] = true
        self.exclude[buf] = nil
    end)
end

function BufferGroup.get_excluded_buffers(self)
    local ks = dict.keys(self.exclude)
    if dict.is_empty(ks) then
        return
    end
    return ks
end

function BufferGroup.create_picker(self, tp)
    local function create_include_buffer_picker()
        local bufs = BufferGroup.get_excluded_buffers(self)
        if not bufs then
            return
        end

        local _ = telescope.load()
        local mod = {}

        function mod.include_buffer(prompt_bufnr)
            BufferGroup.include_buffer(self, unpack(array.map(_:get_selected(prompt_bufnr), function(buf)
                return buf.bufnr
            end)))
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
                    BufferGroup = self.name,
                    bufnr = entry,
                    bufname = bufname,
                }
            end,
        }, {
            mod.default_action,
            { "n", "i", mod.include_buffer },
        }, {
            prompt_title = "excluded buffers in BufferGroup " .. self.name,
        })

        return picker
    end

    local function create_picker(remove)
        local bufs = BufferGroup.list_buffers(self)
        if not bufs then return end

        local items = {
            results = bufs,
            entry_maker = function(entry)
                local bufname = buffer.name(entry)
                return {
                    value = entry,
                    ordinal = entry,
                    BufferGroup = self.name,
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
            array.each(sel, function(buf)
                BufferGroup.remove_buffer(self, buf.bufnr)
            end)
        end

        function mod.open_buffer(prompt_bufnr)
            local sel = _:get_selected(prompt_bufnr)[1]
            if not sel then
                return
            end
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
            BufferGroup.exclude_buffer(self, unpack(array.map(_:get_selected(prompt_bufnr), function(buf)
                return buf.bufnr
            end)))
        end

        local prompt_title
        if remove then
            prompt_title = "remove buffers from BufferGroup = " .. self.name
        else
            prompt_title = "BufferGroup = " .. self.name
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
end

local function get_group(bufnr, group)
    assert(bufnr)
    assert(group)

    group = BufferGroup.buffers[bufnr]
    if not group then return nil, "buffer_not_captured" end

    group = group[group]
    if not group then return nil, "invalid_group" end

    return group
end

BufferGroup.buffer = dict.map(BufferGroup, function (key, value)
    return function (group, bufnr, ...)
        group = get_group(bufnr, group)
        if not group then return end

        return value(group, ...)
    end
end)

BufferGroup.buffer.init = nil
BufferGroup.buffer.init_before = nil

function BufferGroup.buffer.create_picker(bufnr, ...)
    bufnr = bufnr or buffer.bufnr()

    if not buffer.exists(bufnr) then
        return
    end

    local groups = BufferGroup.buffers[bufnr]
    if not groups or dict.is_empty(groups) then
        return
    end

    items = dict.keys(groups)
    items = {
        results = items,
        entry_maker = function(entry)
            local bufname = buffer.name()
            return {
                BufferGroup = entry,
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
        BufferGroup.run_picker(BufferGroup.BufferGroups[sel.BufferGroup])
    end

    function mod.remove_buffers(prompt_bufnr)
        local sel = _:get_selected(prompt_bufnr)[1]
        BufferGroup.run_picker(BufferGroup.BufferGroups[sel.BufferGroup], 'remove')
    end

    function mod.show_excluded_buffers(prompt_bufnr)
        local sel = _:get_selected(prompt_bufnr)[1]
        BufferGroup.run_picker(BufferGroup.BufferGroups[sel.BufferGroup], 'include')
    end

    function mod.change_pattern(prompt_bufnr)
        local sel = _:get_selected(prompt_bufnr)[1]
        local group = BufferGroup.BufferGroups[sel.BufferGroup]
        local pattern = group.pattern
        local userint = input {pattern = {'new pattern' }}
        group.pattern = array.to_array(userint.pattern or group.pattern)

        printf("pattern changed to  %s for BufferGroup %s", dump(group.pattern), group.name)
    end

    return _:create_picker(items, {
        mod.default_action,
        { "n", "e", mod.show_excluded_buffers },
        { "n", "x", mod.remove_buffers },
        { "n", "p", mod.change_pattern },
    }, {
        prompt_title = "BufferGroups for buffer " .. buffer.name(bufnr),
    })
end

function BufferGroup.buffer.run_picker(bufnr, ...)
    bufnr = bufnr or buffer.bufnr()
    local picker = BufferGroup.buffer.create_picker(bufnr, ...)
    if picker then picker:find() end
end

--------------------------------------------------
function BufferGroup.load_mappings(mappings, compile)
    mappings = mappings or BufferGroup.mappings or {}
    if is_empty(mappings) then return end

    return kbd.map_group('BufferGroup', mappings, compile)
end

function BufferGroup.load_autocmds(mappings)
    mappings = mappings or BufferGroup.mappings or {}
    if is_empty(mappings) then return end

    return autocmd.map_group('BufferGroup', mappings, compile)
end

function BufferGroup.load_defaults(defaults)
    defaults = deepcopy(defaults or BufferGroup.defaults)
    local event = defaults.event or "BufEnter"
    defaults.event = nil
    local out = {}

    dict.each(defaults, function(name, spec)
        local pattern

        if is_a.string(spec) then
            pattern = spec
        else
            event = spec.event or event
            pattern = spec.pattern
        end

        out[name] = BufferGroup(name, event, pattern)
        BufferGroup.enable(out[name])
    end)

    return out
end

function BufferGroup.load_commands(commands)
    commands = commands or BufferGroup.commands
    if is_empty(commands) then return end

    return Command.map_group('BufferGroup', commands)
end
