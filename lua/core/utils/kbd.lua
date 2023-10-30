require "core.utils.autocmd"

kbd = kbd or struct("kbd", {
	-- nvim_set_keymap opts
	'buffer',
	'nowait',
	'silent',
	'script',
	'expr',
	'unique',
	'noremap',
	'desc',
	'callback',
	'replace_keycodes',

	-- extract opts
	'command',
    "mode",
    "keys",
    "event",
    "pattern",
    "name",
    "once",
    "leader",
    "localleader",
    "prefix",
    "enabled",
    "autocmd",
    "group",
})

kbd.kbds = kbd.kbds or {}
local enable = vim.keymap.set
local delete = vim.keymap.del
local del = delete

function kbd.opts(self)
	return tfilter(self, function(key, _)
		return strmatch(key,
		'buffer',
		'nowait',
		'silent',
		'script',
		'expr',
		'unique',
		'noremap',
		'desc',
		'callback',
		'replace_keycodes'
		)
	end)
end

function kbd.init(self, mode, ks, callback, rest)
	rest = rest or {}
	mode = mode or 'n'

    local _rest = rest
	rest = is_string(_rest) and {desc = _rest} or _rest

	validate {
		mode = {union('string', 'list'), mode},
		ks = {'string', ks},
		callback = {union('callable', 'string'), callback},
		opts = {'table', rest}
	}

    mode = is_string(mode) and split(mode, "") or mode
	local command = is_string(callback) and callback
	callback = is_callable(callback) and callback
	local prefix = rest.prefix
	local noremap = rest.noremap
	local event = rest.event
	local pattern = rest.pattern
	local once = rest.once
	local buffer = rest.buffer
	local cond = rest.cond
	local localleader = rest.localleader
	local leader = rest.leader
	local name = rest.name
	local group = rest.group or 'Keybinding'
	local desc = rest.desc

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

    if name then
        if group then
            name = group .. "." .. name
        end
    end

	self.mode = mode
	self.keys = ks
	self.command = command
	self.prefix = prefix
	self.noremap = noremap
	self.event = event
	self.pattern = pattern
	self.once = once
	self.buffer = buffer
	self.cond = cond
	self.localleader = localleader
	self.leader = leader
	self.name = name
	self.group = augroup
	self.desc = desc
	self.enabled = false
	self.autocmd = false
    self.callback = callback

	if name then
		kbd.kbds[name] = self
	end

	return self
end

function kbd.enable(self)
    if self.autocmd and autocmd.exists(self.autocmd) then
        return self
    end

	local opts = copy(kbd.opts(self))
	local cond = self.cond
	local callback

	if self.command then 
		callback = self.command
	else
		callback = ''
		opts.callback = self.callback
	end

    if self.event and self.pattern then
        self.autocmd = autocmd(self.event, {
            pattern = self.pattern,
            group = self.group,
            once = self.once,
            callback = function(au_opts)
				if cond and not cond() then return end
				opts = copy(opts)
                opts.buffer = buffer.bufnr()

                enable(self.mode, self.keys, callback, opts)
				self.enabled = true
            end,
        })
    else
        enable(self.mode, self.keys, callback, opts)
		self.enabled = true
    end

    return self
end

function kbd.disable(self)
    if self.buffer then
        if self.buffer then
            del(self.mode, self.keys, { buffer = self.buffer })
        end
    elseif self.events and self.pattern then
        del(self.mode, self.keys, { buffer = buffer.bufnr() })
    else
        del(self.mode, self.keys)
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

    teach(specs, function(name, spec)
        if name == "opts" or name == "apply" then
            return
        end

        if is_a.kbd(spec) then
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

    teach(specs, function(group, spec)
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

    teach(specs, function(group, spec)
        merge(all_mapped, kbd.map_group(group, spec, compile))
    end)

    return all_mapped
end
