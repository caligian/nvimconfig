augroup = {augroups={}, augroups_by_name={}}
autocmd = {autocmds={}, autocmds_by_name={}}

local disable_autocmd = vim.api.nvim_del_autocmd
local enable_autocmd = vim.api.nvim_create_autocmd
local enable_augroup = vim.api.nvim_create_augroup
local disable_augroup = vim.api.nvim_del_augroup_by_id

augroup.exception = {
  duplicate_name = exception 'augroup by this name already exists'
}

autocmd.exception = {
  duplicate_name = exception 'autocmd by this name already exists'
}

function autocmd.new(event, opts)
  validate {
    event = {is {'table', 'string'}, opts},
    opts = {{
      pattern = is {'table', 'string'},
      callback = 'callable',
      name = 'string',
      opt_group = 'string',
    }, opts}
  }

  local name = opts.name
  local exists = autocmd.autocmds_by_name[name]
  if exists then autocmd.exception.duplicate_name:throw(name) end

  local self = {
    name = name,
    event = event,
    pattern = opts.pattern,
    once = opts.once,
    nested = opts.nested,
    callback = opts.callback,
    id = false,
    group = opts.group,
    disable = function (self)
      if not self.id then return end

      local id = self.id
      self.id = false
      disable_autocmd(self.id)

      return id
    end,
    enable = function (self)
      if self.id then return false end

      self.id = enable_autocmd(self.event, {
        pattern = self.pattern,
        once = self.once,
        callback = self.callback,
        group = self.group,
        nested = self.nested,
      })

      autocmd.autocmds_by_name[self.name] = self
      autocmd.autocmds[self.id] = self

      return self
    end,
    is_enabled = function (self)
      if not self.id then return end
      return true
    end,
    is_disabled = function (self)
      if not self.id then return true end
      return
    end,
    delete = function (self)
      if not autocmd.autocmds_by_name[self.name] then return end

      autocmd.autocmds_by_name[self.name] = nil
      autocmd.autocmds[self.id] = nil

      return self
    end,
  }

  return self
end

function augroup.new(name)
  local exists = augroup.augroups_by_name[name]
  if exists then augroup.exception.duplicate_name:throw(name) end
  
  local self = {
    name = name,
    autocmds = {},
    id = false,
    enable = function (self, clear)
      if self.id then return end

      self.id = enable_augroup(self.name, {clear=clear})
      augroup.augroups[self.id] = self
      augroup.augroups_by_name[self.name] = self

      return self.id
    end,
    disable = function (self)
      if not self.id then return end

      local id = self.id
      self.id = false
      disable_augroup(self.id)
      dict.each(self.autocmds, function (_, obj) obj:disable() end)

      return id
    end,
    delete = function (self)
      if not augroup.augroups_by_name[self.name] then return end

      augroup.augroups_by_name[self.name] = nil
      augroup.augroups[self.id] = nil

      return self
    end,
    add_autocmd = function (self, event, opts)
      opts = opts or {}
      opts = vim.deepcopy(opts)
      opts.group = self.name
      self.autocmds[opts.name] = autocmd.new(event, opts)
      self.autocmds[opts.name]:enable()

      return self.autocmds[opts.name]
    end,
    disable_autocmd = function (self, name)
      local au = self.autocmds[self.name]
      if not au or not au.id then return end

      return au:disable()
    end,
    get_enabled = function (self)
      local found = dict.grep(self.autocmds, function (_, obj) return obj.id end)
      if dict.isblank(found) then return end

      return found
    end,
    get_disabled = function (self)
      local found = dict.grep(self.autocmds, function (_, obj) return not obj.id end)
      if dict.isblank(found) then return end

      return found
    end,
  }

  return self
end

function autocmd.with_opts(opts, callback)
  validate {
    preset_opts = {'table', opts},
    names_with_callbacks = {'table', callback},
  }

  dict.each(callback, function (au_name, cb)
    local _opts = dict.merge({ callback = cb, name = au_name  }, opts)
    _opts.name = au_name
    autocmd.new(au_name, _opts)
  end)
end
