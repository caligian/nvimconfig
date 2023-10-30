local enable = vim.api.nvim_create_autocmd
local disable = vim.api.nvim_del_autocmd
local getinfo = vim.api.nvim_get_autocmds
local create_augroup = vim.api.nvim_create_augroup

autocmd = autocmd or struct('autocmd', {
	'id',
	'command',
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

function autocmd.init(self, event, opts)
	local pattern = opts.pattern
	local callback = opts.callback
	local group = opts.group or 'MyGroup'
	local buffers = {}
	local name = opts.name
    local cb = opts.callback
	local callback
	local once = opts.once
	local nested = opts.nested
	local command = opts.command
	local desc = opts.desc
	local buf = opts.buffer

	assert_unless(cb or command, 'expected command or callback')

	if not command then
		function callback(opts)
			cb(opts)
			append(buffers, buffer.bufnr())
		end
	end

	self.event = event
	self.pattern = pattern
	self.group = group
	self.name = name
	self.callback = callback
	self.command = command
	self.buffer = buf

	opts = {
		pattern = pattern,
		command = command,
		callback = callback,
		nested = nested,
		once = once,
		group = group,
		desc = desc,
		buffer = buf,
	}

	if group then
		create_augroup(group, {clear = false })
	end

	self.id =  enable(event, opts)

    if name then
        if group then
            name = group .. '.' .. name
        end

        autocmd.autocmds[name] = self
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
    found = each(found, function (x)
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
    return getinfo(spec)
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

    teach(mappings, function (key, value)
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

    tmap(groups, function(name, group)
        merge(all_groups, autocmd.map_group(name, group, compile))
    end)

    return all_groups
end
