if not Autocmd then
    class.Autocmd()
end

user.autocmd = Autocmd
builtin.makepath(Autocmd, 'id')
builtin.makepath(Autocmd, 'group')

function Autocmd.create_augroup(group, clear)
    local id = vim.api.nvim_create_augroup(group, { clear = clear })
    Autocmd.group[id] = {}
    Autocmd.group[group] = Autocmd.group[id]

    return id
end

function Autocmd.delete_augroup(id)
    return vim.api.nvim_del_autocmd(Autocmd.id[id].group_id)
end

function Autocmd._init(self, group, clear)
    self.enabled = false

    if group then
        self.group_id = Autocmd.create_augroup(group, clear)
        self.group = group
        self.clear = clear
    end

    return self
end

function Autocmd.create(self, event, pattern, callback, opts)
    opts = opts or {}
    self = vim.deepcopy(self)
    self.event = builtin.ensure_list(event)
    self.pattern = builtin.ensure_list(pattern)
    self.opts = opts or {}
    self.nested = opts.nested
    self.name = false
    self.once = opts.once
    self.id = false
    self.callback = false
    local nested = self.nested
    local once = self.once
    pattern = self.pattern
    event = self.event
    local id = self.id
    local group = self.group
    local name = opts.name or sprintf('%s::%s', table.concat(self.event, ','), table.concat(self.pattern, ','))
    self.name = name
    local _callback = function()
        if builtin.is_type(callback, 'string') then
            vim.cmd(callback)
        else
            callback()
        end
    end

    if once then
        self.callback = function()
            self.enabled = false
            _callback()
        end
    end
    self.callback = self.callback or _callback

    id = vim.api.nvim_create_autocmd(event, {
        callback = self.callback,
        pattern = pattern,
        once = once,
        nested = nested,
    })
    self.id = id
    self.enabled = true

    if group then
        builtin.makepath(Autocmd.group, group)
        Autocmd.group[group][name] = self
    end

    builtin.update(Autocmd.group, { group_id, id }, self)
    builtin.update(Autocmd.group, { group_id, name }, self)
    builtin.update(Autocmd.id, { id }, self)
    builtin.update(Autocmd.id, { name }, self)

    return self
end

function Autocmd.disable(self)
    vim.api.nvim_del_autocmd(self.id)
    self.enabled = false

    return self
end

function Autocmd.delete(self)
    if not self.enabled then return self end

    Autocmd.disable()
    Autocmd.id[self.id] = nil
    Autocmd.id[self.name] = nil
    Autocmd.group[self.id] = nil
    Autocmd.group[self.name] = nil

    return self
end

return Autocmd
