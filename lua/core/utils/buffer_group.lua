buffer_group = buffer_group or struct("buffer_group", { "buffers", "name", "event", "pattern", "callbacks", "exclude", "autocmd" })
buffer_group.buffers = buffer_group.buffers or {}
buffer_group.buffer_groups = buffer_group.buffer_groups or {}
buffer_group.mappings = buffer_group.mappings or {}
buffer_group.autocmds = buffer_group.autocmds or {}

function buffer_group.init(self, name, event, pattern)
    validate {
        name = { "string", name },
        pattern = { union("list", "string"), pattern },
        opt_event = { union("list", "string"), event },
    }

    return merge(self, {
        name = name,
        event = to_list(event or "BufEnter"),
        pattern = to_list(pattern),
        callbacks = {},
        exclude = {},
        buffers = {},
        autocmd = false,
    })
end

function buffer_group.is_valid_buffer(self, bufnr)
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

function buffer_group.exclude_buffer(self, ...)
    local success = {}
    each({ ... }, function(buf)
        buf = buffer.bufnr(buf)

        if not self.buffers[buf] then
            return
        elseif self.exclude[buf] then
            return
        end

        self.exclude[buf] = true
        self.buffers[buf] = nil

        append(success, buf)
    end)

    if #success == 0 then
        return nil, "invalid_buffer"
    else
        return success
    end
end

function buffer_group.remove_buffer(self, ...)
    local removed = {}
    each({ ... }, function(bufnr)
        bufnr = buffer.bufnr(bufnr)
        if not self.buffers[bufnr] then
            return
        end

        append(removed, bufnr)
        self.buffers[bufnr] = nil

        local exists, exists_t = get(buffer_group.buffers, { bufnr, self.name })

        if exists then
            exists_t[self.name] = nil
        end
        self.exclude[bufnr] = true
    end)

    if is_empty(removed) then
        return
    else
        return removed
    end
end

function buffer_group.buffer_exists(self, bufnr)
    return self.buffers[bufnr] or false
end

function buffer_group.prune(self)
    each(self.buffers, function(bufnr, _)
        if not buffer.exists(bufnr) or self.exclude[bufnr] then
            self.buffers[bufnr] = nil
        end
    end)

    local bufs = keys(self.buffers)
    if is_empty(bufs) then
        return
    else
        return bufs
    end
end

function buffer_group.add_buffer(self, ...)
    local added = {}
    each({ ... }, function(bufnr)
        if not buffer_group.is_valid_buffer(self, bufnr) or self.exclude[bufnr] then
            return
        else
            append(added, bufnr)
        end

        buffer_group.buffers[bufnr] = buffer_group.buffers[bufnr] or {}
        buffer_group.buffers[bufnr][self.name] = self
        self.buffers[bufnr] = true
    end)

    if #added == 0 then
        return nil, "invalid_buffer"
    end
    return added
end

function buffer_group.enable(self)
    if self.autocmd then
        return self.autocmd
    end

    local au = autocmd.map(self.event, {
        pattern = "*",
        callback = function()
            buffer_group.add_buffer(self, buffer.bufnr())
        end,
        group = "buffer_group",
        name = self.name,
    })

    self.autocmd = au

    return au
end

function buffer_group.list_buffers(self, callback)
    local bufs = buffer_group.prune(self)
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

function buffer_group.run_picker(self, tp)
    local picker = buffer_group.create_picker(self, tp)
    if not picker then
        return
    end
    picker:find()
end

function buffer_group.include_buffer(self, ...)
    each({ ... }, function(buf)
        if not self.exclude[buf] then
            return
        end

        self.buffers[buf] = true
        self.exclude[buf] = nil
    end)
end

function buffer_group.get_excluded_buffers(self)
    local ks = keys(self.exclude)
    if is_empty(ks) then
        return
    end
    return ks
end

function buffer_group.create_picker(self, tp)
    local function create_include_buffer_picker()
        local bufs = buffer_group.get_excluded_buffers(self)
        if not bufs then
            return
        end

        local _ = load_telescope()
        local mod = {}

        function mod.include_buffer(sel)
            buffer_group.include_buffer(self, unpack(map(sel, function(buf)
                return buf.bufnr
            end)))
        end

        mod.default_action = mod.include_buffer

        local picker = _.create({
            results = bufs,
            entry_maker = function(entry)
                local bufname = buffer.name(entry)

                return {
                    display = bufname,
                    value = entry,
                    ordinal = entry,
                    name = self.name,
                    bufnr = entry,
                    bufname = bufname,
                }
            end,
        }, {
            mod.default_action,
            { "n", "i", mod.include_buffer },
        }, {
            prompt_title = "excluded buffers in buffer_group " .. self.name,
        })

        return picker
    end

    local function create_picker(remove)
        local bufs = buffer_group.list_buffers(self)
        if not bufs then return end

        local items = {
            results = bufs,
            entry_maker = function(entry)
                local bufname = buffer.name(entry)
                return {
                    value = entry,
                    ordinal = entry,
                    name = self.name,
                    display = bufname,
                    bufname = bufname,
                    bufnr = entry,
                }
            end,
        }

        local _ = load_telescope()
        local mod = {}

        function mod.remove_buffer(sel)
            each(sel, function(buf)
                buffer_group.remove_buffer(self, buf.bufnr)
            end)
        end

        function mod.open_buffer(sel)
            buffer.open(sel[1].bufnr)
        end

        function mod.default_action(sel)
            if remove then
                mod.remove_buffer(sel)
            else
                mod.open_buffer(sel)
            end
        end

        function mod.exclude_buffer(sel)
            buffer_group.exclude_buffer(self, unpack(map(sel, function(buf)
                return buf.bufnr
            end)))
        end

        local prompt_title
        if remove then
            prompt_title = "remove buffers from buffer_group = " .. self.name
        else
            prompt_title = "buffer_group = " .. self.name
        end

        local picker = _.create(items, {
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

    group = buffer_group.buffers[bufnr]
    if not group then return nil, "buffer_not_captured" end

    group = group[group]
    if not group then return nil, "invalid_group" end

    return group
end

buffer_group.buffer = map(buffer_group, function (key, value)
    return function (group, bufnr, ...)
        group = get_group(bufnr, group)
        if not group then return end

        return value(group, ...)
    end
end)

buffer_group.buffer.init = nil
buffer_group.buffer.init_before = nil

function buffer_group.buffer.create_picker(bufnr, ...)
    bufnr = bufnr or buffer.bufnr()

    if not buffer.exists(bufnr) then
        return
    end

    local groups = buffer_group.buffers[bufnr]
    if not groups or is_empty(groups) then
        return
    end

    items = keys(groups)
    items = {
        results = items,
        entry_maker = function(entry)
            local bufname = buffer.name()
            return {
                name = entry,
                bufnr = bufnr,
                bufname = bufname,
                value = entry,
                display = sprintf(
                    "%-15s = %s :: %s",
                    entry,
                    join(groups[entry].event, ", "),
                    join(groups[entry].pattern, ", ")
                ),
                ordinal = bufnr,
            }
        end,
    }

    local mod = {}
    local _ = load_telescope()

    function mod.default_action(sel)
        buffer_group.run_picker(buffer_group.buffer_groups[sel[1].name])
    end

    function mod.remove_buffers(sel)
        each(sel, function (obj)
            buffer_group.run_picker(buffer_group.buffer_groups[obj.name], 'remove')
        end)
    end

    function mod.show_excluded_buffers(sel)
        buffer_group.run_picker(buffer_group.buffer_groups[sel[1].name], 'include')
    end

    function mod.change_pattern(sel)
        sel = sel[1]
        local group = buffer_group.buffer_groups[sel.name]
        local pattern = group.pattern
        local userint = input {pattern = {'new pattern' }}
        group.pattern = to_list(userint.pattern or group.pattern)

        printf("pattern changed to  %s for buffer_group %s", dump(group.pattern), group.name)
    end

    return _.create(items, {
        mod.default_action,
        { "n", "e", mod.show_excluded_buffers },
        { "n", "x", mod.remove_buffers },
        { "n", "p", mod.change_pattern },
    }, {
        prompt_title = "buffer_groups for buffer " .. buffer.name(bufnr),
    })
end

function buffer_group.buffer.run_picker(bufnr, ...)
    bufnr = bufnr or buffer.bufnr()
    local picker = buffer_group.buffer.create_picker(bufnr, ...)
    if picker then picker:find() end
end

--------------------------------------------------
function buffer_group.set_mappings(mappings, compile)
    mappings = mappings or buffer_group.mappings or {}
    if is_empty(mappings) then return end

    return kbd.map_group('buffer_group', mappings, compile)
end

function buffer_group.set_autocmds(mappings)
    mappings = mappings or buffer_group.mappings or {}
    if is_empty(mappings) then return end

    return autocmd.map_group('buffer_group', mappings, compile)
end

function buffer_group.load_defaults(defaults)
    defaults = deepcopy(defaults or buffer_group.defaults)
    local event = defaults.event or "BufEnter"
    defaults.event = nil
    local out = {}

    teach(defaults, function(name, spec)
        local pattern

        if is_a.string(spec) then
            pattern = spec
        else
            event = spec.event or event
            pattern = spec.pattern
        end

        out[name] = buffer_group(name, event, pattern)
        buffer_group.enable(out[name])
    end)

    return out
end

function buffer_group.get_statusline_string(bufnr)
    local state = buffer_group.buffers[bufnr]
    if not state or is_empty(state) then
        return
    end

    return "<" .. join(keys(state), " ") .. ">"
end
