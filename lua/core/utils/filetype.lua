require 'core.utils.autocmd'
require 'core.utils.kbd'
require 'core.utils.lsp'

local mt = {}
filetype = setmetatable({filetypes = {}, id = 1}, mt)

function filetype.new(name)
  validate.filetype('string', name)

  local self = {
    name = name,
    augroup = 'filetype_' .. name,
    user_config_require_path = 'user.ft.' .. name,
    config_require_path = 'core.ft.' .. name,
    load_path = function (p)
      if not path.exists(p) then
        return
      end

      local ok, msg = pcall(function ()
        loadfile(p)()
        return true
      end)

      return ok, msg
    end,
    setup_lsp = function (self)
      if not self.lsp_server then return end

      local server = self.lsp_server
      local name, config

      if is_a.string(server) then
        config = {}
        name = server
      else
        config = server
        name = server[1]
        server[1] = nil
      end

      lsp.setup_server(name, config)

      return true
    end,
    load_config = function (self, is_user)
      local ok, msg
      if is_user then
        ok, msg = pcall(require, self.user_config_require_path)
      else
        ok, msg = pcall(require, self.config_require_path)
      end
      return ok, msg
    end,
    reload_config = function (self, is_user)
      if is_user then
        ok, msg = pcall(function ()
          return loadfile(utils.req2path(self.user_config_require_path))()
        end)
      else
        ok, msg = pcall(function ()
          return loadfile(utils.req2path(self.config_require_path))()
        end)
      end
      return ok, msg
    end,
    add_autocmd = function (self, opts)
      opts = opts or {}
      opts = deepcopy(opts)
      opts.group = self.augroup
      opts.pattern = self.name

      return autocmd.new('FileType', opts)
    end,
    add_autocmds_with_opts = function (self, opts, autocmds)
      opts = deepcopy(opts)
      opts.group = self.augroup
      opts.event = 'FileType'
      opts.pattern = self.name

      autocmds = deepcopy(autocmds)

      dict.each(autocmds, function (_, au_spec)
        au_spec.name = 'filetype.' .. self.name .. '.' .. au_spec.name
      end)

      autocmd.map_with_opts(opts, autocmds)
    end,
    map_with_opts = function(self, opts, mappings)
      opts = deepcopy(opts)
      opts.apply = function(mode, ks, cb, rest)
        rest.pattern = self.name
        rest.event = 'FileType'
        rest.name = 'filetype.' .. self.name .. '.' .. rest.name
        return mode, ks, cb, rest
      end
      kbd.map_with_opts(opts, mappings)
    end,
    map = function (self, mode, ks, cb, rest)
      if is_a.string(rest) then rest = {desc=rest} end
      rest = deepcopy(rest)
      rest.name = 'filetype.' .. self.name .. '.' .. rest.name
      rest.event = 'FileType'
      rest.pattern = self.name
      return kbd.map(mode, ks, cb, rest)
    end,
  }

  filetype.filetypes[name] = self
  return self
end

function filetype.get(ft, attrib)
  if not filetype.filetypes[ft] then filetype.filetypes[ft] = filetype.new(ft) end
  if attrib then return filetype.filetypes[ft][attrib] end
  return filetype.filetypes[ft]
end

function filetype.load_specs(is_user)
  if not is_user then
    array.each(dir.getallfiles(user.dir .. '/lua/core/ft/'), function (f)
      require('core.ft.' ..  path.basename(f:gsub('%.lua$', '')))
    end)
  else
    array.each(dir.getallfiles(user.user_dir .. '/lua/user/ft/'), function (f)
      require('core.ft.' ..  path.basename(f:gsub('%.lua$', '')))
    end)
  end
end

return filetype
