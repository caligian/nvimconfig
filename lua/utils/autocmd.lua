--- Autocommand creater for this framework
--
class 'Autocmd'

A = Autocmd
A.ids = A.ids or {}
A.defaults = A.defaults or {}
A.groups = A.groups or {}

function Autocmd._init(self, event, opts)
	assert(isa.t(opts))
	assert(opts.callback)
	assert(opts.pattern)

	local augroup
	local group = copy(opts.group or {})
	local name = opts.name
	opts.name = nil
	if type(group) == "string" then
		augroup = vim.api.nvim_create_augroup(group)
	else
		group[1] = group[1] or "UserGlobal"
		group[2] = group[2] or {}
		augroup = vim.api.nvim_create_augroup(unpack(group))
		group = group[1]
	end

	local callback = opts.callback
	opts.callback = function()
		self.enabled = true
		if isa.s(callback) then
			vim.cmd(callback)
		else
			callback()
		end
	end

	if opts.once then
		callback = opts.callback
		opts.callback = function()
			self.enabled = false
			callback()
		end
	end

	local id = autocmd(event, opts)
	self.id = id
	self.gid = augroup
	self.group = group
	self.event = event
	self.enabled = false
	self.opts = opts
	self.opts.name = name

	for key, value in pairs(opts) do
		self[key] = value
	end

	update(Autocmd.ids, id, self)
	update(Autocmd.groups, { augroup, id }, self)

	if name then
		Autocmd.defaults[name] = self
	end
	self.name = name

	return self
end

function Autocmd.disable (self)
	if not self.enabled then
		return
	end
	vim.api.nvim_del_autocmd(self.id)
	self.enabled = false

	return self
end

function Autocmd.delete(self)
	self:disable()

	if self.name then
		Autocmd.defaults[self.name] = nil
	end

	Autocmd.ids[self.id] = nil
	Autocmd.groups[self.group][self.id] = nil

	return self
end

function Autocmd.replace (self, opts)
	self:delete()

	local opts = self.opts
	opts.callback = callback

	return Autocmd(self.event, opts)
end
