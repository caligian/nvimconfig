augroup = {STATE={}}
autocmd = {STATE={}}

local disable_autocmd = vim.api.nvim_del_autocmd
local enable_autocmd = vim.api.nvim_create_autocmd
local enable_augroup = vim.api.nvim_create_augroup
local disable_augroup = vim.api.nvim_del_augroup_by_id

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

  if autocmd.STATE[name] then error('autocmd ' .. name .. ' already exists') end

  autocmd.STATE[name] = {
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

      self.id = false
      disable_autocmd(self.id)

      return true
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

      return self.id
    end,
  }

  return autocmd.STATE[name]
end

function augroup.new(name)
  if augroup.STATE[name] then error('augroup ' .. name .. ' already exists') end
  
  augroup.STATE[name] = {
    name = name,
    autocmds = {},
    id = false,
    enable = function (self, clear)
      if self.id then return end

      self.id = enable_augroup(self.name, {clear=clear})
      return self.id
    end,
    disable = function (self)
      if not self.id then return end

      self.id = false
      disable_augroup(self.id)

      return self.id
    end,
    add_autocmd = function (self, event, opts)
      opts = opts or {}
      opts = array.deepcopy(opts)
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

  return augroup.STATE[name]
end

function autocmd.with_opts(opts, callback)
  validate {
    preset_opts = {'table', opts},
    names_with_callbacks = {'table', callback},
  }

  dict.each(callback, function (au_name, callback)
    local _opts = dict.merge({ callback = callback }, opts)
    autocmd.new(au_name, _opts)
  end)
end
