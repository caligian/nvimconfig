class "Lang"

Lang.langs = Lang.langs or {}
local AUTOCMD_ID = 1

function Lang._init(self, lang, opts)
  validate {
    filetype = { "s", lang },
    opts = { "t", opts },
  }

  if Lang.langs[lang] then
    return Lang.langs[lang]
  end

  self.name = lang
  self.autocmd = false

  if opts.hooks then
    for _, h in ipairs(opts.hooks) do
      if is_a.t(h) then
        log_pcall(function()
          self:hook(unpack(h))
        end)
      else
        log_pcall(function()
          self:hook(h)
        end)
      end
    end
  end

  if opts.bo then
    self:setbufopts(opts.bo)
  end
  if opts.kbd then
    self:map(unpack(opts.kbd))
  end
  if opts.linters then
    opts.linters = tolist(opts.linters)
  end
  if opts.server and is_a.s(opts.server) then
    opts.server = { name = opts.server }
  end

  Lang.langs[lang] = merge(self, opts or {})

  return self
end

function Lang.hook(self, callback, opts)
  return log_pcall(function()
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
  if self.autocmd[id] then
    self.autocmd[id]:delete()
  end
end

function Lang.setbufopts(self, bo)
  log_pcall(function()
    self:hook(function()
      local bufnr = vim.fn.bufnr()
      for key, value in pairs(bo) do
        vim.api.nvim_buf_set_option(bufnr, key, value)
      end
    end)
  end)
end

function Lang.map(self, opts, ...)
  local args = { ... }
  log_pcall(function()
    opts = opts or {}
    for i, kbd in ipairs(args) do
      assert(is_a.s(kbd))
      assert(#kbd >= 2)
      local o = kbd[3] or {}
      if is_a.s(o) then
        o = { desc = o }
      end
      o.event = "FileType"
      o.pattern = self.name
      args[i] = o
    end

    return Keybinding(opts, unpack(args))
  end)
end

function Lang.load(lang)
  return log_pcall(function()
    local c = require("core.lang.ft." .. lang)
    local u = req("user.lang.ft." .. lang)

    if not c then
      return
    end

    return Lang(lang, lmerge(u or {}, c))
  end)
end

function Lang.loadall()
  return log_pcall(function()
    local src = joinpath(vim.fn.stdpath "config", "lua", "core", "lang", "ft")
    local dirs = dir.getdirectories(src)
    for _, ft in ipairs(dirs) do
      Lang.load(basename(ft))
    end
  end)
end
