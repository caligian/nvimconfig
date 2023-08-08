local enable = vim.api.nvim_create_autocmd
local disable = vim.api.nvim_del_autocmd
local get = vim.api.nvim_get_autocmds
local create_augroup = vim.api.nvim_create_augroup

autocmd = autocmd or struct.new('autocmd', {
    'id',
    'name',
    'event',
    'pattern',
    'callback',
    'group',
    'once',
    'buffers',
    'buffer',
    'nested',
})

autocmd.autocmds = autocmd.autocmds or {}

function autocmd.init_before(event, opts)
	if is_struct(event, 'autocmd') then return event end

	return {
		event = event, 
		pattern = opts.pattern,
		callback = opts.callback,
		group = opts.group or 'MyGroup',
		buffers = {},
		name = opts.name,
	}
end

function autocmd.init(self)
    local callback = self.callback

    function self.callback(opts)
        if is_string(callback) then
            vim.cmd(callback)
        else
            callback(opts)
        end
        append(self.buffers, buffer.bufnr())
    end

    if self.name then
        local name = self.name

        if self.group then
            name = self.group .. '.' .. name
        end

        local exists = autocmd.autocmds[name]
        if exists and autocmd.exists(exists) then return exists end

        autocmd.autocmds[self.name] = self
    end

    return self
end

function autocmd.exists(self)
    local found, msg = pcall(get, {group = self.group, event = self.event, buffer = self.buffers })

    if not found then
        if msg and msg:match "Invalid .group." then
            create_augroup(self.group, {})
        end

        return
    end

    found = msg
    found = array.grep(found, function (x)
        return self.id and x.id == self.id
    end)

    if #found > 0 then
        return self
    end
end

function autocmd.enable(self)
    if autocmd.exists(self) then
        return self.id
    end

    self.id = enable(self.event, {
        pattern = self.pattern,
        group = self.group,
        callback = self.callback,
        once = self.once,
        nested = self.nested,
    })

    return id
end

function autocmd.disable(self)
    if not autocmd.exists(self) then
        return 
    end

    return disable(self.id)
end

function autocmd.find(spec)
    return get(spec)
end

function autocmd.map(...)
    local x = autocmd(...)
    local id = autocmd.enable(x)

    return x, id
end

function autocmd.map_group(group, mappings, compile)
    local opts = mappings.opts
    local apply = mappings.apply
    local mapped = {}

    dict.each(mappings, function (key, value)
        if key == 'opts' or key == 'apply' then
            return 
        end

        value = deepcopy(value)

        local event, rest
        local event, rest = unpack(value)
        local name = group .. '.' .. key
        rest.group = group

        if opts then
            rest = merge(copy(rest), opts)
        end

        rest.name = name

        if apply then 
            event, rest = apply(event, rest) 
        end

        if compile then
            mapped[name] = autocmd(event, rest)
        else
            mapped[name] = autocmd.map(event, rest)
        end
    end)

    return mapped
end

function autocmd.map_groups(groups, compile)
    local all_groups = {}

    dict.each(groups, function(name, group)
        merge(all_groups, autocmd.map_group(name, group, compile))
    end)

    return all_groups
end
