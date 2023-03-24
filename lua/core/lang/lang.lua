class "Lang"

Lang.langs = Lang.langs or {}
local AUTOCMD_ID = 1

function Lang._init(self, lang, opts)
  validate {
    filetype = { "s", lang },
    ["?opts"] = {
      {
        __nonexistent = false,
        ["?hooks"] = is { "f", "t" },
        ["?bo"] = "t",
        ["?wo"] = "t",
        ["?kbd"] = "t",
        ["?compile"] = "s",
        ["?build"] = "s",
        ["?test"] = "s",
        ["?linters"] = is { "s", "t" },
        ["?formatters"] = "t",
        ["?server"] = is { "s", 't' },
        ["?repl"] = is {"s", 't'},
      },
      opts,
    },
  }

  if Lang.langs[lang] then return Lang.langs[lang] end

  self.name = lang
  self.autocmd = false

  if opts.hooks then
    if is_a.f(opts.hooks) then
      self:hook(opts.hooks)
    else
      for _, h in ipairs(opts.hooks) do
        if is_a.t(h) then
          utils.log_pcall(function() self:hook(unpack(h)) end)
        else
          utils.log_pcall(function() self:hook(h) end)
        end
      end
    end
  end

  if opts.bo then self:setbufopts(opts.bo) end
  if opts.kbd then self:map(unpack(opts.kbd)) end
  if opts.linters then opts.linters = table.tolist(opts.linters) end
  if opts.server and is_a.s(opts.server) then
    opts.server = { name = opts.server }
  end

  Lang.langs[lang] = table.merge(self, opts or {})

  return self
end

function Lang.hook(self, callback, opts)
  return utils.log_pcall(function()
    self.autocmd = self.autocmd or {}
    opts = opts or {}
    opts.pattern = self.name
    opts.callback = callback
    local au = Autocmd("FileType", opts)
    self.autocmd[AUTOCMD_ID] = au
    AUTOCMD_ID = AUTOCMD_ID + 1

    return au
  end)
end

function Lang.unhook(self, id)
  if self.autocmd[id] then self.autocmd[id]:delete() end
end

function Lang.setbufopts(self, bo)
  utils.log_pcall(function()
    self:hook(function()
      local bufnr = vim.fn.bufnr()
      for key, value in pairs(bo) do
        vim.api.nvim_buf_set_option(bufnr, key, value)
      end
    end)
  end)
end

function Lang.setwinopts(self, wo)
  utils.log_pcall(function()
    self:hook(function()
      local winid = vim.fn.bufwinid(0)
      if winid == -1 then return end

      for name, val in pairs(wo) do
        vim.api.nvim_win_set_option(winid, name, val)
      end
    end)
  end)
end

function Lang.map(self, opts, ...)
  local args = { ... }

  utils.log_pcall(function()
    opts = opts or {}
    opts.event = "FileType"
    opts.pattern = self.name
    K.bind(opts, unpack(args))
  end)
end

function Lang.load(lang, opts)
  if not opts then
    local c = require("core.lang.ft." .. lang)
    local u = req("user.lang.ft." .. lang)
    local a, b = is_a.t(c), is_a.t(u)

    if a and b then
      table.merge(c, u)
      Lang(lang, c)
    elseif a then
      Lang(lang, c)
    elseif b then
      Lang(lang, u)
    else 
      assert(c or u, lang .. ': no config supplied')
    end
  else
    Lang(lang, opts)
  end
end

function Lang.loadall()
  return utils.log_pcall(function()
    local src =
    utils.joinpath(vim.fn.stdpath "config", "lua", "core", "lang", "ft")
    local dirs = dir.getdirectories(src)
    for _, ft in ipairs(dirs) do
      Lang.load(utils.basename(ft))
    end
  end)
end

Lang.load('lua')
