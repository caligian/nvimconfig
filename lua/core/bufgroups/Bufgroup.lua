-- groups are matched by lua regex
-- Bufgroup = {
--   GROUPS = {},
-- }

if not Bufgroup then class "Bufgroup" end
Bufgroup.BUFGROUPS = Bufgroup.BUFGROUPS or {}
Bufgroup.POOLS = Bufgroup.POOLS or {}
Bufgroup.BUFFERS = {}

function Bufgroup:init(name, event, pattern, pool)
  validate {
    name = { "string", name },
    event = { is { "string", "table" }, event },
    pattern = { is { "string", "table" }, pattern },
    ["?pool"] = { "string", pool },
  }

  pool = pool or "default"
  name = pool .. '.'.. name
  self.name = name
  self.event = table.tolist(event or "BufAdd")
  self.pattern = table.tolist(pattern)
  self.augroup = false
  self.callbacks = {}
  self.buffers = {}
  self.pool = pool

  dict.update(Bufgroup.POOLS, { self.pool, self.name }, self)
  dict.update(Bufgroup.BUFGROUPS, self.name, self)
end

function Bufgroup:is_eligible(bufnr)
  bufnr = bufnr or vim.fn.bufnr()

  if vim.fn.bufexists(bufnr) == -1 then return false end

  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local success = false
  for _, pattern in ipairs(self.pattern) do
    if bufname:match(pattern) then
      success = true
      break
    end
  end

  if not success then return false end

  return bufnr, bufname
end

function Bufgroup:add(bufnr)
  local bufnr, bufname = self:is_eligible(bufnr)
  if not bufnr then return false end

  self.buffers[bufnr] = {
    bufnr = bufnr,
    bufname = bufname,
    pool = self.pool,
    event = self.event,
    pattern = self.pattern,
    group = self.name,
  }

  table.makepath(Bufgroup.BUFFERS, bufnr, 'pools')
  table.makepath(Bufgroup.BUFFERS, bufnr, 'groups')
  Bufgroup.BUFFERS[bufnr].pools[self.pool] = self.pool
  Bufgroup.BUFFERS[bufnr].groups[self.name] = self.name

  return self
end

function Bufgroup:remove(bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  self.buffers[bufnr] = nil

  return self
end

function Bufgroup:delete()
  if Bufgroup.POOLS[self.pool] then
    Bufgroup.POOLS[self.pool][self.name] = nil
  end

  return self
end

function Bufgroup:list(telescope)
  if dict.isblank(self.buffers) then
    return false
  elseif not telescope then
    return self.buffers
  end

  return {
    results = array.imap(
      dict.values(self.buffers),
      function(idx, state) return { state.bufnr, state.bufname, idx } end
    ),
    entry_maker = function(entry)
      return {
        value = entry,
        ordinal = entry[#entry],
        display = entry[2],
        bufname = entry[2],
        bufnr = entry[1],
        pool = self.pool,
        group = self.name,
      }
    end,
  }
end

function Bufgroup:enable()
  if self.augroup then return end

  self.augroup = Augroup("bufgroup" .. self.name)
  self.augroup:add("register", self.event, {
    pattern = "*",
    callback = function(opts)
      if self:add() then
        array.each(
          dict.values(self.callbacks),
          function(callback) callback(self, opts) end
        )
      end
    end,
  })

  return self
end

function Bufgroup:register(name, callback)
  validate {
    name = { "s", name },
    callback = { "callable", callback },
  }

  self.callbacks[name] = callback

  return self
end

function Bufgroup.get(pool, name, ass)
  assert(name, 'no group name supplied')

  local group
  if not pool then
    group = Bufgroup.BUFGROUPS[name]
  else
    group = dict.contains(Bufgroup.POOLS, pool, name)
  end

  if ass then
    assert(group, sprintf("group %s not found", name))
  end

  return group
end

function Bufgroup:create_picker(opts)
  local ls = self:list(true)
  if not ls then return end
  local _ = utils.telescope.load()
  local mod = _.create_actions_mod()

  function mod.remove(sel)
    self:remove(sel.bufnr)
    print("Removed buffer " .. sel.bufname)
  end

  function mod.add_pattern()
    local pattern = vim.fn.input "Lua pattern % "
    if #pattern == 0 then return end
    self.pattern[#self.pattern + 1] = pattern
  end

  function mod.edit_pattern()
    local pattern =
      vim.fn.input("Lua pattern % ", table.concat(self.pattern, " :: "))
    if #pattern == 0 then return end
    self.pattern = pattern:split "%s*::%s*"
  end

  local function default_action(bufnr)
    local sel = _.get_selected(bufnr)[1]
    vim.cmd("b " .. sel.bufnr)
  end

  local picker = _.new_picker(self:list(true), {
    default_action,
    { "n", "x", mod.remove },
    { "n", "a", mod.add_pattern },
    { "n", "e", mod.edit_pattern },
  }, {
    prompt_title = "Buffer group: " .. self.name,
  })

  return picker
end

function Bufgroup.create_main_picker()
  local ls = table.keys(Bufgroup.BUFGROUPS)
  table.sort(ls)
  if array.isblank(ls) then return end
  local _ = utils.telescope.load()

  local function default_action(prompt_bufnr)
    local sel = _.get_selected(prompt_bufnr)[1][1]
    local group = Bufgroup.BUFGROUPS[sel]
    local picker = group:create_picker()
    if picker then picker:find() end
  end

  return _.new_picker(
    ls,
    default_action,
    {prompt_title = 'All buffer groups'}
  )
end
