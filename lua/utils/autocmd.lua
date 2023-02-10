-- Augroup
class("Augroup")
Augroup.id = Augroup.id or {}

function Augroup._init(self, group, opts)
	opts = opts or {}
	for key, value in pairs(opts) do
		self[key] = value
	end
	self.name = group
	self.id = vim.api.nvim_create_augroup(group, opts)

	if Augroup.id[self.id] then
		return Augroup.id[self.id]
	else
		V.update(Augroup.id, self.id, self)
		self.enabled = true
		self.autocmd = {}

		return self
	end
end

function Augroup.clear(self)
	vim.cmd(sprintf("augroup %s | au! | augroup END", self.name))
end

function Augroup.delete(self)
	if not self.enabled then
		return
	end

	self.enabled = false
	vim.api.nvim_del_augroup_by_id(self.id)
end

-- Autocmd
class("Autocmd")
Autocmd.id = Autocmd.id or {}

function Autocmd._init(self, event, opts)
	self.id = vim.api.nvim_create_autocmd(event, opts)
	opts.group = opts.group or "UserGlobal"
	self.augroup = Augroup(opts.group)
	self.augroup[self.id] = self

	local callback = opts.callback
	if opts.once then
		opts.callback = function()
			self.enabled = false
		end
	end
	for key, value in pairs(opts) do
		self[key] = value
	end
	self.event = event

	return self
end

function Autocmd.disable(self)
	if not self.enabled then
		return
	end
	vim.api.nvim_del_autocmd(self.id)
	self.enabled = false
end

function Autocmd.delete(self)
	self:disable()
	Autocmd.id[self.id] = nil
	self.autocmd[self.id] = nil
end
