require "core.utils.autocmd"

kbd = struct.new("kbd", {
    "mode",
    "keys",
    "callback",
    "opts",
    "event",
    "pattern",
    "name",
    "once",
    "leader",
    "localleader",
    "prefix",
    "enabled",
    "autocmd",
    "augroup",
    "desc",
})

kbd.kbds = {}
local enable = vim.keymap.set
local delete = vim.keymap.del

function kbd.init_before(mode, ks, callback, rest)
    if is_struct(mode, "kbd") then
        return mode
    end

    mode = is_string(mode) and mode:splat() or mode
    rest = is_string(rest) and { desc = rest } or rest
    rest = rest or {}

    local not_match =
        array.to_dict { "mode", "event", "pattern", "name", "once", "leader", "localleader", "prefix", "augroup" }

    local opts, custom = {}, {}

    dict.each(rest, function(key, v)
        if not_match[key] then
            custom[key] = v
        else
            opts[key] = v
        end
    end)

    local self = merge({
        mode = mode,
        keys = ks,
        callback = callback,
        opts = opts,
        desc = opts.desc,
    }, custom)

    return self
end

function kbd.init(self)
    local mode, ks, callback, opts = self.mode, self.keys, self.callback, self.opts
    local name, event, pattern, once, prefix, localleader, leader, group =
        self.name, self.even, self.pattern, self.once, self.prefix, self.localleader, self.leader, self.group

    mode = is_string(mode) and string.splat(mode) or mode

    if prefix and (localleader or leader) then
        if localleader then
            ks = "<localleader>" .. prefix .. ks
        else
            ks = "<leader>" .. prefix .. ks
        end
    elseif localleader then
        ks = "<localleader>" .. ks
    elseif leader then
        ks = "<leader>" .. ks
    end

    self.keys = ks
    self.mode = mode
    self.callback = callback

    if name then
        if group then
            name = group .. "." .. name
        end

        self.name = name
        kbd.kbds[name] = self
    end


    return self
end

function kbd.enable(self)
    if self.autocmd and autocmd.exists(self.autocmd) then
        return self
    end

    if self.event and self.pattern then
        self.autocmd = autocmd.map(self.event, {
            pattern = self.pattern,
            group = self.group,
            once = self.once,
            callback = function(au_opts)
                local opts = copy(self.opts)
                opts.buffer = buffer.bufnr()
                enable(self.mode, self.keys, self.callback, opts)
            end,
        })
    else
        enable(self.mode, self.keys, self.callback, self.opts)
    end

    return self
end

function kbd.disable(self)
    if self.opts.buffer then
        if self.opts.buffer then
            del(mode, keys, { buffer = self.opts.buffer })
        end
    elseif self.events and self.pattern then
        del(mode, keys, { buffer = buffer.bufnr() })
    else
        del(mode, keys)
    end

    if self.autocmd then
        autocmd.disable(self.autocmd)
    end

    return self
end

function kbd.map(mode, ks, callback, opts)
    return kbd.enable(kbd(mode, ks, callback, opts))
end

function kbd.noremap(mode, ks, callback, opts)
    opts = is_string(opts) and { desc = opts } or opts
    opts = opts or {}
    opts.noremap = true

    return kbd.map(mode, ks, callback, opts)
end

function kbd.map_group(group_name, specs, compile)
    local mapped = {}
    local opts = specs.opts
    local apply = specs.apply

    dict.each(specs, function(name, spec)
        if name == "opts" or name == "apply" then
            return
        end

        if is_struct(spec, 'kbd') then
            kbd.enable(spec)
            return
        end

        name = group_name .. "." .. name
        local mode, ks, callback, rest

        if opts then
            ks, callback, rest = unpack(spec)
            rest = is_string(rest) and { desc = rest } or rest
            rest = merge(copy(rest or {}), opts or {})
            mode = rest.mode or "n"
        else
            mode, ks, callback, rest = unpack(spec)
            rest = is_string(rest) and { desc = rest } or rest
            rest = copy(rest or {})
            rest.name = name
        end

        if apply then
            mode, ks, callback, rest = apply(mode, ks, callback, rest)
        end

        if compile then
            mapped[name] = kbd(mode, ks, callback, rest)
        else
            mapped[name] = kbd.map(mode, ks, callback, rest)
        end
    end)

    return mapped
end

function kbd.map_groups(specs, compile)
    local all_mapped = {}
    local opts = specs.opts
    specs = deepcopy(specs)
    specs.opts = nil

    dict.each(specs, function(group, spec)
        if is_dict_of(spec, 'kbd') then
            merge(all_mapped, kbd.map_group(group, spec))
        elseif group == "inherit" then
            return
        elseif spec.opts and opts then
            merge(spec.opts, opts)
        elseif spec.inherit then
            spec.opts = opts
        end

        spec.inherit = nil
        specs[group] = spec
    end)

    dict.each(specs, function(group, spec)
        merge(all_mapped, kbd.map_group(group, spec, compile))
    end)

    return all_mapped
end
