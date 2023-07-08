autocmd = {autocmds={}, autocmds_by_name = {}, augroups = {}, augroups_by_name={}}

local disable_autocmd = vim.api.nvim_del_autocmd
local enable_autocmd = vim.api.nvim_create_autocmd
local enable_augroup = vim.api.nvim_create_augroup
local disable_augroup = vim.api.nvim_del_augroup_by_id

autocmd.exception = {
  duplicate_name = exception 'autocmd by this name already exists'
}

function autocmd.create_augroup(name, clear)
  if autocmd.augroups_by_name[name] then return autocmd.augroups[name] end

  local group = {}
  local id = enable_augroup(name, {clear=clear})
  group.id = id
  group.name = name
  autocmd.augroups_by_name[name] = group
  autocmd.augroups[id] = group

  return group
end

local function get_augroup(name)
  local group = autocmd.augroups_by_name[name] or autocmd.augroups[name] 
  return group
end

function autocmd.list_augroup(name)
  local group = get_augroup(name)
  if not group then return end

  group = copy(group) 
  group.id = nil
  group.name = nil

  return group
end

function autocmd.disable_augroup(name)
  local group = get_augroup(name)
  if not group or not group.id then return end

  local id = group.id
  group.id = false

  dict.each(group, function(group_name, autocmds)
    if group_name == 'id' or group_name == 'name' then return end
    dict.each(autocmds, function(au_name, au_obj) au_obj:disable() end)
  end)
  
  return id
end

function autocmd.delete_augroup(name)
  local id = autocmd.disable_augroup(name)
  if not id or not get_augroup(id) then return end

  autocmd.augroups[id] = nil
  autocmd.augroups_by_name[name] = nil

  return id
end

function autocmd.new(event, opts)
  validate {
    event = {is {'table', 'string'}, opts},
    opts = {{
      pattern = is {'table', 'string'},
      callback = is {'string', 'callable'},
      name = 'string',
      opt_group = 'string',
    }, opts}
  }

  opts = deepcopy(opts)
  local name = opts.name
  local exists = autocmd.autocmds_by_name[name]
  -- if exists and not exists:is_disabled() then autocmd.exception.duplicate_name:throw(name) end

  opts.group = opts.group or 'default'
  local clear_group = opts.clear_group
  opts.clear_group = nil

  if not autocmd.augroups[opts.group] then autocmd.create_augroup(opts.group, clear_group) end

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
        callback = function(au_opts)
          if is_a.callable(self.callback) then
            self.callback(self, au_opts)
          else
            vim.cmd(self.callback)
          end

          if self.once then
            self.id = false
          end
        end,
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

function autocmd.map(...)
  return autocmd.new(...):enable()
end

function autocmd.map_with_opts(opts, callback)
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

function autocmd.map_groups(groups)
  local out = {}

  dict.each(deepcopy(groups), function (group_name, group_spec)
    if group_name == 'apply' or group_name == 'opts' then return end

    local apply = group_spec.apply
    group_spec.apply = nil
    dict.each(group_spec, function (au_name, au_spec)
      au_spec[2].group = group_name
      au_spec[2].name = 'au.' .. group_name .. '.' .. au_name
      local event, opts = unpack(au_spec)
      if apply then event, opts = apply(event, opts) end
      out[au_spec[2].name] = {event, opts}
    end)
  end)

  dict.each(out, function (_, spec)
      autocmd.map(unpack(spec))
  end)

  return out
end

function autocmd.map_group(name, spec)
    return autocmd.map_groups({[name] = spec})
end
