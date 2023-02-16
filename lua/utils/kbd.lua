-- @classmod Keybinding Keybinding creater for neovim
class("Keybinding")

Keybinding.buffer = Keybinding.buffer or {}
Keybinding.id = Keybinding.id or {}
Keybinding.defaults = Keybinding.defaults or {}
local id = 1

function Keybinding:update()
  V.update(Keybinding.id, self.id, self)

  if self.buffer then
    V.update(Keybinding.buffer, { self.buffer, self.id }, self)
  end

  return self
end

local function getkbdopts(opts)
  if V.isstring(opts) then
    return { desc = opts }
  end

  local o = {}
  for key, value in pairs(opts) do
    if
      not V.match(key, "once", "nested", "group", "pattern", "event", "leader", "prefix", "mode")
    then
      o[key] = value
    end
  end

  return o
end

local function getauopts(opts)
  local o = {}
  for key, value in pairs(opts) do
    if V.match(key, "once", "nested", "group", "pattern", "event") then
      o[key] = value
    end
  end
  return o
end

function Keybinding:_init(mode, lhs, cb, rest)
  assert(mode, "No mode provided")
  assert(lhs, "No LHS provided")
  assert(cb, "No RHS provided")

  if V.isstring(mode) then
    mode = vim.split(mode, "")
  end

  rest = rest or {}
  local opts = getkbdopts(rest)
  local au = getauopts(rest)

  if rest.leader then
    lhs = "<leader>" .. lhs
  elseif rest.localleader then
    lhs = "<localleader>" .. lhs
  elseif rest.prefix then
    lhs = rest.prefix .. lhs
  end

  opts.buffer = opts.buffer == true and vim.fn.buffer() or opts.buffer

  self.id = id
  id = id + 1
  if au.event and au.pattern then
    self.autocmd = Autocmd(au.event, {
      pattern = au.pattern,
      once = au.once,
      nested = au.nested,
      group = au.group,
      callback = function()
        opts.buffer = vim.fn.bufnr()
        vim.keymap.set(mode, lhs, cb, opts)
        self.enabled = true
        self.buffer = opts.buffer
        self:update()
      end,
    })
  elseif opts.buffer then
    vim.keymap.set(mode, lhs, cb, opts)
    self.autocmd = Autocmd("BufEnter", {
      pattern = "<buffer=" .. opts.buffer .. ">",
      callback = function()
        self.enabled = true
        self:update()
      end,
      once = au.once,
      nested = au.nested,
    })
  else
    vim.keymap.set(mode, lhs, cb, opts)
    self.enabled = true
    self:update()
  end

  self.mode = mode
  self.lhs = lhs
  self.callback = cb
  self.opts = opts

  return self
end

function Keybinding:disable()
  if not self.enabled then
    return
  end

  if self.autocmd then
    self.autocmd:delete()
    self.autocmd = nil
    if self.buffer then
      for _, mode in ipairs(self.mode) do
        vim.api.nvim_buf_del_keymap(self.buffer, mode, self.lhs)
      end
    end
    self.enabled = false
  else
    for _, mode in ipairs(self.mode) do
      vim.api.nvim_del_keymap(mode, self.lhs)
    end
    self.enabled = false
  end

  return self
end

function Keybinding:delete()
  if not self.enabled then
    return
  end

  self:disable()
  Keybinding.id[self.id] = nil
  Keybinding._check[self.hash] = nil

  return self
end

function Keybinding.bind(opts, ...)
  opts = opts or {}
  local mode = vim.deepcopy(opts.mode or "n")
  opts.mode = nil
  local args = { ... }
  local bind = function(kbd)
    assert(V.isa(kbd, "table"))
    assert(#kbd >= 2)

    if kbd[3] then
      if V.isstring(kbd[3]) then
        kbd[3] = { desc = kbd[3] }
      end
    end
    kbd[3] = V.lmerge(kbd[3] or {}, opts)

    return Keybinding(mode, unpack(kbd))
  end

  if #args == 1 then
    return bind(args[1])
  else
    V.each(bind, args)
  end
end

function Keybinding.map(mode, lhs, cb, opts)
  return Keybinding(mode, lhs, cb, opts)
end

function Keybinding.noremap(mode, lhs, cb, opts)
  opts = opts or {}
  opts.noremap = true

  return Keybinding(mode, lhs, cb, opts)
end

function Keybinding:replace(cb, opts)
  assert(cb)

  self:delete()

  return Keybinding(self.mode, self.lhs, cb, V.lmerge(opts or {}, self.opts))
end
