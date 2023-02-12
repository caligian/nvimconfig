class("Keybinding")

Keybinding.buffer = Keybinding.buffer or {}
Keybinding.id = Keybinding.id or {}
local id = 1

function Keybinding.update(self)
  V.update(Keybinding.id, self.id, self)

  if self.bufnr then
    V.update(Keybinding.buffer, { self.bufnr, self.id }, self)
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

function Keybinding._init(self, mode, lhs, cb, rest)
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

  opts.buffer = opts.buffer == true and vim.fn.bufnr() or opts.buffer

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

function Keybinding.disable(self)
  if not self.enabled then
    return
  end

  if self.autocmd then
    self.autocmd:disable()
    if self.bufnr then
      for _, mode in ipairs(self.mode) do
        vim.api.nvim_buf_del_keymap(self.bufnr, self.mode, self.lhs)
      end
    end
    self.enabled = false
  else
    for _, mode in ipairs(self.mode) do
      vim.api.nvim_del_keymap(self.mode, self.lhs)
    end
    self.enabled = false
  end

  return self
end

function Keybinding.bind(opts, ...)
  opts = opts or {}
  local mode = vim.deepcopy(opts.mode or "n")
  opts.mode = nil
  for _, kbd in ipairs({ ... }) do
    assert(V.isa(kbd, "table"))
    assert(#kbd >= 2)

    if kbd[3] then
      if V.isstring(kbd[3]) then
        kbd[3] = { desc = kbd[3] }
      end
    end
    kbd[3] = V.lmerge(kbd[3] or {}, opts)
    Keybinding(mode, unpack(kbd))
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
