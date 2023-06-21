local mt = {}
filetypes = setmetatable({STATE = {}}, mt)

function filetypes.new(name)
  validate.filetype('string', name)

  return {
    name = name,
    augroup = Augroup('filetype_' .. name),
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

      local lsp = plugin.lsp
      local server = self.lsp_server
      local name, config

      if is_a.string(server) then
        config = {}
        name = server
      else
        config = server
        name = server[1]
      end

      lsp.methods.setup_server(name, config)

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
          return loadfile(utils.req2path(self.config_require_path))()
      end
      return ok, msg
    end,
    hook = function (self, callback, name)
      self.augroup:add('FileType', {
        pattern = '*',
        callback = callback,
        name = name,
      })
    end,
    bind = function (self, opts)
      validate.opts('table', opts)

      if K._ismultiple(opts) then
        validate.opts('table', opts)

        opts = dict.deepcopy(opts)
        opts.event = 'FileType'
        opts.pattern = self.name

        K._applymultiple(opts)
      else
        for i=1, #opts do
          validate.opts('table', opts)

          opts[4] = dict.deepcopy(opts[4] or {})
          opts[4].event = 'FileType'
          opts[4].pattern = self.name

          K.map(unpack(opts[i]))
        end
      end
    end,
    set_buffer_option = function (self, ...)
      local args = {...}
      self:hook(function ()
        buffer.setoption(buffer.bufnr(), unpack(args))
      end)
    end,
    set_buffer_var = function (self, ...)
      local args = {...}
      self:hook(function ()
        buffer.setvar(buffer.bufnr(), unpack(args))
      end)
    end,
  }
end

function mt:__index(ft)
  if not self.STATE[ft] then
    self.STATE[ft] = filetypes.new(ft)
  end
  return self.STATE[ft]
end

return filetypes
