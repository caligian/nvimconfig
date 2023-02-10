class('Autocmd')

Autocmd.id = Autocmd.id or {}
Autocmd.group = Autocmd.group or {}

function Autocmd.create_augroup(group, clear)
	local id = vim.api.nvim_create_augroup(group, { clear = clear })

	local g = { group = group, id = id }

	V.makepath(Autocmd.group, id)
	V.makepath(Autocmd.group, group)
	Autocmd.group[id] = Autocmd.group[id] or g
	Autocmd.group[group] = Autocmd.group[group] or g

	return id
end

function Autocmd.delete_augroup(group)
	if Autocmd.group[group] then
		vim.api.nvim_del_autocmd(Autocmd.group[group].id)
		Autocmd.group[group] = nil
	end
end

local function autocmd(group, event, pattern, callback, once, nested, clear)
	group = group or 'UserGlobal'
	local gid = false
	if group:match('^!') or not Autocmd.group[group] then
		gid = Autocmd.create_augroup(group, true)
	else
		gid = Autocmd.create_augroup(group)
	end
	local opts = { once = once, nested = nested, pattern = pattern, group = group, callback = callback }
	local id = vim.api.nvim_create_autocmd(event, opts)
	return id, gid
end

function Autocmd._init(self, group, event, pattern, callback, opts)
	assert(event)
	assert(pattern)
	assert(callback)

	opts = opts or {}
	event = V.ensure_list(event)
	pattern = V.ensure_list(pattern)
	local nested = opts.nested
	local once = opts.once
	local id, gid
	local group = opts.group
	local _callback = function()
		if V.is_type(callback, 'string') then
            print('laude')
			vim.cmd(callback)
		else
			callback()
		end

		if once then self.enabled = false end
	end

	id, gid = autocmd(group, event, pattern, _callback, once, nested)

	self.group = group
	self.event = event
	self.pattern = pattern
	self.once = once
	self.nested = nested
	self.group = group
	self.gid = gid
	self.id = id
	self.callback = _callback

	V.update(Autocmd.id, { id }, self)
	V.update(Autocmd.group, { gid, id }, self)

	return self
end

function Autocmd.disable(self)
	vim.api.nvim_del_autocmd(self.id)
	self.enabled = false
end

function Autocmd.delete(self)
	if not self.enabled then return self end

	Autocmd.disable()
	Autocmd.id[self.id] = nil
end
