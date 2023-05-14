Filetype = Filetype or class "Filetype"
Filetype.ft = Filetype.ft or {}
Filetype.AUTOCMD_ID = Filetype.AUTOCMD_ID or 1
Filetype.loaded = Filetype.loaded == nil and false or Filetype.loaded
user.filetype = Filetype.ft
local add_ft = vim.filetype.add

function Filetype.setupall()
  dict.each(Filetype.ft, function(_, obj) obj:load() end)
end

function Filetype:setup(opts)
  opts = opts or self:todict()

  validate {
    spec = {
      {
        opt_bo = "table",
        opt_wo = "table",
        opt_kbd = "table",
        opt_compile = "string",
        opt_build = "string",
        opt_test = "string",
        opt_linters = is { "string", "table" },
        opt_formatters = "table",
        opt_server = is { "string", "table" },
        opt_repl = is { "string", "table" },
        opt_extension = is "string",
        opt_pattern = is "string",
        opt_hooks = is 'table',
      },
      opts,
    },
  }

  if opts.wo then
    local exists = dict.get(self.augroup, { "autocmd", "window_options" })
    if exists then exists:disable() end

    self.augroup:add("Filetype", {
      callback = function(au) buffer.setopts(au.bufnr, opts.window_options) end,
      pattern = self.name,
      name = 'window_options',
    })
  end

  if opts.buffer_options then
    local exists = dict.get(self.augroup, { "autocmd", "buffer_options" })
    if exists then exists:disable() end

    self.augroup:add("Filetype", {
      callback = function(au) buffer.setopts(au.buf, opts.buffer_options) end,
      pattern = self.name,
    })
  end

  if opts.kbd then self:map(opts.kbd) end

  if opts.server and is_a.string(opts.server) then
    opts.server = { name = opts.server }
  end

  if opts.extension then
    add_ft { extension = { [opts.extension] = ft } }
  elseif opts.pattern then
    add_ft { pattern = { [opts.pattern] = ft } }
  end

  if opts.hooks then
    self:hook(self.hooks)
  end
end

function Filetype.create(ft)
  if not user.filetype[ft] then return Filetype(ft) end
  return user.filetype[ft]
end

function Filetype:init(ft, opts)
  self.name = ft
  self.augroup = Augroup.create("filetype_" .. ft)

  if opts then
    dict.merge(self, opts)
    self:load()
  end

  Filetype.ft[ft] = self
end

function Filetype:map(opts)
  opts = utils.copy(opts)
  opts.event = "FileType"
  opts.pattern = self.name

  K.bind(opts)
end

function Filetype:bind(opts) self:map(opts) end

function Filetype:load()
  local builtin = "core.ft." .. self.name
  local override = "user.ft." .. self.name

  if utils.req2path(builtin) then require(builtin) end
  if utils.req2path(override) then require(override) end

  self:setup()
end

function Filetype.loadall()
  local dest = path.join(vim.fn.stdpath "config", "lua", "core", "ft")
  local configured = dir.getfiles(dest)

  array.each(configured, function(fname)
    fname = path.basename(fname)
    fname = fname:gsub(".lua$", "")
    local ft = Filetype.create(fname)
    ft:load()
  end)

  Filetype.loaded = true
end

function Filetype:hook(name, callback)
  if is_callable(name) then
    self.augroup:add('FileType', {
      pattern = self.name,
      callback = name,
    })
  else
    self.augroup:add('FileType', {
      pattern = self.name,
      callback = callback,
      name = name,
    })
  end
end

--------------------------------------------------------------------------------
local function get_by_name(name, attrib)
  return dict.get(Filetype.ft, { name, attrib })
end

local function get(attrib)
  local has = {}

  dict.each(Filetype.ft, function(ft, config)
    if config[attrib] then has[ft] = config[attrib] end
  end)

  return has
end

Filetype.get = multimethod()
Filetype.get:set(get_by_name, "string", "string")
Filetype.get:set(get, "string")

--------------------------------------------------------------------------------
filetype = setmetatable({}, {
  __call = function(self, ft, spec) return Filetype(ft, spec) end,

  __index = function(self, ft)
    if user.filetype[ft] then return user.filetype[ft] end

    return Filetype(ft)
  end,

  __newindex = function(self, ft, spec)
    ft = Filetype.create(ft)
    dict.merge(ft, spec)

    return ft
  end,
})

--------------------------------------------------------------------------------
return Filetype
