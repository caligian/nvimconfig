plugin = plugin or {}
plugin.plugins =  {}

function plugin.new(name, spec)
  local self = {
    augroup = 'plugin_' .. name,
    user_only = false,
    spec = spec,
    name = name,
    mappings = false,
    autocmds = false,
    setup = false,
    config = false,
    user_config_require_path = 'user.plugins.' .. name,
    config_require_path = 'core.plugins.' .. name,
    set_autocmds = function (self, apply)
      if not self.autocmds or self.autocmds.__flattened then return end

      local autocmds = deepcopy(self.autocmds)
      local current_apply = autocmds.apply

      function autocmds.apply(event, opts)
        if current_apply then current_apply(event, opts) end
        apply(event, opts)
      end

      self.autocmds = autocmd.flatten_groups(autocmds, true)
      return self.autocmds
    end,
    set_mappings = function (self, apply)
      if not self.mappings or self.mappings.__flattened then return end

      self.mappings = deepcopy(self.mappings)

      self.mappings.apply = function (mode, ks, cb, rest)
        return mode, ks, cb, rest
      end

      self.mappings = kbd.flatten_groups(self.mappings, true)

      return self.mappings
    end,
    config_exists = function (self, is_user)
      if is_user then return utils.req2path(self.user_config_require_path) end
      return utils.req2path(self.config_require_path)
    end,
    load_config = function (self, is_user)
      local user_path = utils.req2path(self.user_config_require_path)
      local builtin_path = utils.req2path(self.config_require_path)
      local ok, msg

      if builtin_path then ok, msg = pcall(require, self.config_require_path) end
      if user_path then ok, msg = pcall(require, self.user_config_require_path) end

      return ok, msg
    end,
    reload_config = function (self, is_user)
      if is_user then
        ok, msg = pcall(function ()
          return require(self.user_config_require_path)
        end)
      else
        ok, msg = pcall(function ()
          return require(self.config_require_path)
        end)
      end
      return ok, msg
    end,
    map_with_opts = function(self, opts, mappings)
      opts = deepcopy(opts)
      opts.apply = function(mode, ks, cb, rest)
        return mode, ks, cb, rest
      end
      kbd.map_with_opts(opts, mappings)
    end,
    map = function (self, mode, ks, cb, rest)
      if is_a.string(rest) then rest = {desc=rest} end
      rest = deepcopy(rest)
      return kbd.map(mode, ks, cb, rest)
    end,
    add_autocmd = function (self, event, opts)
      opts = deepcopy(opts)
      opts.group = self.augroup
      return autocmd.new(event, opts)
    end,
    add_autocmds_with_opts = function (self, opts, autocmds)
      opts = deepcopy(opts)
      opts.group = self.augroup
      autocmds = deepcopy(autocmds)
      autocmd.map_with_opts(opts, autocmds)
    end
  }

  local config = spec.config
  function spec.config()
    if config then config(self) end

    if self.user_only then
      self:load_config(true)
    else
      self:load_config(true)
      self:load_config()
    end

    if self.autocmds then self:set_autocmds() end
    if self.mappings then self:set_mappings() end
    if self.setup then self:setup() end
  end

  plugin.plugins[name] = self
  return plugin.plugins[name]
end

function plugin.load_specs(req_path)
  req_path = req_path or 'core.plugins'
  local specs = require(req_path)
  dict.each(specs, plugin.new)

  return plugin.plugins
end

function plugin.get(name, callback)
  if not plugin.plugins[name] then return end

  local plug = plugin.plugins[name]
  if callback then callback(plug) end

  return plug
end

function plugin.to_lazy_spec()
  if dict.isblank(plugin.plugins) then plugin.load_specs() end
  return array.map(dict.values(plugin.plugins), function (obj)
    return obj.spec
  end)
end

function plugin.setup_lazy()
  require('lazy').setup(plugin.to_lazy_spec())
end
