class("Lang")

Lang.langs = Lang.langs or {}
local id = 1

function Lang.hook(self, callback, opts)
  self.autocmd = self.autocmd or {}
  opts = opts or {}
  opts.pattern = self.name
  opts.callback = callback
  id = id + 1
  local au = Autocmd("FileType", opts)
  self.autocmd[au.id] = au

  return au
end

function Lang.unhook(self, id)
  if self.autocmd[id] then
    self.autocmd[id]:delete()
  end
end

function Lang.setbufopts(self, bo)
  self:hook(function()
    local bufnr = vim.fn.bufnr()
    for key, value in pairs(bo) do
      vim.api.nvim_buf_set_option(bufnr, key, value)
    end
  end)
end

function Lang.map(self, opts, ...)
  opts = opts or {}
  local args = { ... }
  for i, kbd in ipairs(args) do
    assert(V.isstring(kbd))
    assert(#kbd >= 2)
    local o = kbd[3] or {}
    if V.isstring(o) then
      o = { desc = o }
    end
    o.event = "FileType"
    o.pattern = self.name
    args[i] = o
  end

  return Keybinding(opts, unpack(args))
end

function Lang._init(self, lang, opts)
  if Lang.langs[lang] then
    return Lang.langs[lang]
  end

  self.name = lang
  self.autocmd = false

  if opts.hooks then
    for _, h in pairs(opts.hooks) do
      if V.istable(h) then
        self:hook(unpack(h))
      else
        self:hook(h)
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
    opts.linters = V.tolist(opts.linters)
  end
  if opts.server and V.isstring(opts.server) then
    opts.server = { name = opts.server }
  end

  self = V.merge(self, opts or {})
  Lang.langs[lang] = self

  return self
end

function Lang.load(lang)
  local c = V.require("core.lang.ft." .. lang)
  local u = V.require("user.lang.ft." .. lang)
  if not c then
    return
  end

  return Lang(lang, V.lmerge(c, u or {}))
end

function Lang.loadall()
  local src = V.joinpath(vim.fn.stdpath("config"), "lua", "core", "lang", "ft")
  local dirs = dir.getdirectories(src)
  for _, ft in ipairs(dirs) do
    Lang.load(V.basename(ft))
  end
end
