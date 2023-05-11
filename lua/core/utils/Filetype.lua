Filetype = Filetype or class "Filetype"
Filetype.ft = Filetype.ft or {}
Filetype.AUTOCMD_ID = Filetype.AUTOCMD_ID or 1
Filetype.loaded = Filetype.loaded == nil and false or Filetype.loaded

function Filetype:init(ft, opts)
  validate {
    filetype = { "string", ft },
    ["?opts"] = {
      {
        ["?hooks"] = is { "callable", "table" },
        ["?bo"] = "table",
        ["?wo"] = "table",
        ["?kbd"] = "table",
        ["?compile"] = "string",
        ["?build"] = "string",
        ["?test"] = "string",
        ["?linters"] = is { "string", "table" },
        ["?formatters"] = "table",
        ["?server"] = is { "string", "table" },
        ["?repl"] = is { "string", "table" },
      },
      opts,
    },
  }

  self.name = ft
  self.autocmd = false

  if opts.hooks then
    array.each(array.tolist(opts.hooks), function(cb)
      self:hook(cb)
    end)
  end

  if opts.bo then
    self:setbufopts(opts.bo)
  end
  if opts.kbd then
    self:map(opts.kbd)
  end
  if opts.linters then
    opts.linters = array.tolist(opts.linters)
  end
  if opts.server and is_a.string(opts.server) then
    opts.server = { name = opts.server }
  end

  Filetype.ft[ft] = dict.merge(self, opts or {})
end

function Filetype:hook(callback, opts)
  self.autocmd = self.autocmd or {}
  opts = opts or {}
  opts.pattern = self.name
  opts.callback = callback
  local au = Autocmd("FileType", opts)
  self.autocmd[Filetype.AUTOCMD_ID] = au
  Filetype.AUTOCMD_ID = Filetype.AUTOCMD_ID + 1

  return au
end

function Filetype:unhook(id)
  if self.autocmd[id] then
    self.autocmd[id]:delete()
  end
end

function Filetype:setbufopts(bo)
  self:hook(function()
    local bufnr = vim.fn.bufnr()
    for key, value in pairs(bo) do
      vim.api.nvim_buf_set_option(bufnr, key, value)
    end
  end)
end

function Filetype:setwinopts(wo)
  self:hook(function()
    local winid = vim.fn.bufwinid(0)
    if winid == -1 then
      return
    end

    for name, val in pairs(wo) do
      vim.api.nvim_win_set_option(winid, name, val)
    end
  end)
end

function Filetype:map(opts)
  opts.event = "FileType"
  opts.pattern = self.name
  K.bind(opts)
end

function Filetype.load(ft, opts)
  local builtin = 'core.ft.' .. ft
  local override = 'user.ft.' .. ft

  if not utils.req2path(builtin) and not utils.req2path(override) then
    return 
  elseif not opts then
    builtin = utils.copy(require(builtin))
    override = utils.require(override) or {}
    opts = dict.merge(builtin, override)
  end

  return Filetype(ft, opts)
end

function Filetype.loadall()
  local dest = path.join(vim.fn.stdpath "config", "lua", "core", "ft")
  local configured = dir.getfiles(dest)

  array.each(configured, function(fname)
    fname = path.basename(fname)
    fname = fname:gsub(".lua$", "")
    Filetype.load(fname)
  end)

  Filetype.loaded = true
end

Filetype.get = multimethod()

Filetype.get:set(function(name, attrib)
  return dict.get(Filetype.ft, { name, attrib })
end, "string", "string")

Filetype.get:set(function(attrib)
  local has = {}
  dict.each(Filetype.ft, function(ft, config)
    if config[attrib] then
      has[ft] = config[attrib]
    end
  end)

  return has
end, "string")

return Filetype
