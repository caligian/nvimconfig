user.bufgroup = user.bufgroup or {
  POOL = {},
  BUFFER = {},
  BUFGROUP = {},
}

Bufgroup = Class.new "Bufgroup"
local exception = Exception "BufgroupException"
exception:set {
  invalid_group = "valid group expected",
  invalid_buffer = "valid buffer expected",
}

function Bufgroup:init(name, event, pattern, pool)
  validate {
    name = { "string", name },
    event = { is { "string", "table" }, event },
    pattern = { is { "string", "table" }, pattern },
    ["?pool"] = { "string", pool },
  }

  pool = pool or "default"
  name = pool .. "." .. name
  self.name = name
  self.event = array.tolist(event or "BufRead")
  self.pattern = array.tolist(pattern)
  self.augroup = false
  self.buffer = {}
  self.pool = pool

  dict.update(user.bufgroup.POOL, { pool, name }, self)
  dict.update(user.bufgroup.BUFGROUP, name, self)
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

  self.buffer[bufnr] = buffer.name(bufnr)
  dict.update(user.bufgroup.BUFFER, { bufnr, "pools", self.pool }, self.pool)
  dict.update(user.bufgroup.BUFFER, { bufnr, "groups", self.name }, self)

  return self
end

function Bufgroup:disable()
  if self.augroup then self.augroup:disable() end
end

function Bufgroup:remove(bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  self.buffer[bufnr] = nil
  user.bufgroup.BUFFER[bufnr] = nil

  return self
end

function Bufgroup:clean()
  dict.each(self.buffer, function (bufnr, _)
    if not buffer.exists(bufnr) then
      self.buffer[bufnr] = nil
      user.bufgroup.BUFFER[bufnr] = nil
    end
  end)
end

function Bufgroup:delete()
  dict.delete(user.bufgroup.POOL, self.pool)
  dict.delete(user.bufgroup, self.name)

  return self
end

function Bufgroup:list(telescope)
  self:clean()

  if dict.isblank(self.buffer) then
    return false
  elseif not telescope then
    return #self.buffer > 0 and self.buffer
  end

  return {
    results = array.imap(
      dict.keys(self.buffer),
      function(idx, bufnr) return { bufnr, self.buffer[bufnr], idx } end
    ),
    entry_maker = function(entry)
      return {
        value = entry[2],
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

function Bufgroup:enable(clear)
  if self.augroup then return end
  local augroup_name = "bufgroup_" .. self.name:gsub('[^0-9a-zA-Z_]', '_')
  self.augroup = Augroup(augroup_name, clear)

  self.augroup:add('BufRead', {
    pattern = '*',
    callback = function () self:add(vim.fn.bufnr()) end,
    name = 'bufgroup_add_' .. self.name
  })

  return self.augroup
end

function Bufgroup.get(name, pool, ass)
  local group
  if not pool then
    group = user.bufgroup.BUFGROUP[name]
  else
    group = dict.contains(user.bufgroup.POOL, pool, name)
  end

  if ass then
    exception.invalid_group:throw_unless(group, { name = name, pool = pool })
  end

  return group
end

function Bufgroup:create_picker(remover)
  local ls = self:list(true)
  if not ls then return end
  local _ = utils.telescope.load()
  local mod = _.create_actions_mod()

  local function remove(sel)
    self:remove(sel.bufnr)
    print("Removed buffer " .. sel.bufname)
  end

  function mod.remove(sel)
    remove(sel)
  end

  function mod.add_pattern()
    local pattern = vim.fn.input "Lua pattern % "
    if #pattern == 0 then return end
    self.pattern[#self.pattern + 1] = pattern
  end

  local function default_action(bufnr)
    if remover then
      array.each(_.get_selected(bufnr), remove)
    else
      local sel = _.get_selected(bufnr)[1]
      vim.cmd("b " .. sel.bufnr)
    end
  end

  local title
  title = remover
    and ('(Remover) Buffer group: ' .. self.name) 
    or ('Buffer group ' .. self.name)

  local picker = _.new_picker(self:list(true), {
    default_action,
    { "n", "x", mod.remove },
    { "n", "a", mod.add_pattern },
  }, {
    prompt_title = title,
  })

  return picker
end

function Bufgroup.create_main_picker(remover)
  local ls = array.sort(
    array.grep(
      dict.keys(user.bufgroup.BUFGROUP),
      function(k) return k ~= "POOL" and k ~= "BUFFER" end
    )
  )
  if array.isblank(ls) then return end
  local _ = utils.telescope.load()
  local mod = _.create_actions_mod()

  local function remove(sel)
    array.each(sel, function(buffer)
      buffer = buffer[1]
      local group = user.bufgroup.BUFGROUP[buffer]
      group:delete()
    end)
  end

  function mod.remove(sel) remove(sel) end

  local function default_action(prompt_bufnr)
    if remover then
      array.each(sel, remove)
    else
      local sel = _.get_selected(prompt_bufnr)[1][1]
      local group = user.bufgroup.BUFGROUP[sel]
      if group then 
        local picker = group:create_picker()
        if picker then picker:find() end
      end
    end
  end

  return _.new_picker(
    ls,
    {
      default_action,
      {'n', 'x', mod.remove}
    },
    { prompt_title = "All buffer groups" }
  )
end

function Bufgroup.list_pool(pool_name, telescope)
  local pool = user.bufgroup.POOL[pool_name]
  if not pool then return end
  local ks = dict.keys(pool)

  if dict.isblank(ks) then
    return
  elseif not telescope then
    local out = {}
    for i = 1, #ks do
      out[group] = pool[ks[i]]:list()
    end
    return out
  end

  return {
    results = ks,
    entry_maker = function(entry)
      local group = pool[entry]
      return {
        value = entry,
        display = sprintf(
          "%s @ %s",
          entry,
          table.concat(group.pattern, " :: ")
        ),
        ordinal = -1,
        group = entry,
        pool = pool_name,
        pattern = group.event,
        event = group.pattern,
        buffer = group.buffer,
      }
    end,
  }
end

function Bufgroup.create_pool_picker(pool_name, remover)
  local ls = Bufgroup.list_pool(pool_name, true)
  if not ls then return end
  local _ = utils.telescope.load()
  local mod = _.create_actions_mod()
  local input = vim.fn.input
  local pool = user.bufgroup.POOL[pool_name]

  local function remove(sel)
    local group = pool[sel.group]
    local connected = group.buffer
    if array.isblank(connected) then
      sprintf("Deleted buffer group: %s.%s", sel.pool, sel.group)
      group:delete()
    else
      group:create_picker(true):find()
    end
  end

  function mod.remove(sel) remove(sel) end

  function mod.add(_)
    local group = input "Buffer group name % "
    if #group == 0 then return false end

    local pattern = input "Patterns to match (delim = ::) % "
    if #pattern == 0 then return false end
    pattern = pattern:split "%s*::%s*"

    Bufgroup(group, "BufRead", pattern, pool_name)
  end

  function mod.grep(sel)
    local group = pool[sel.group]
    local grep = require("telescope.builtin").grep_string
    local opts = copy(_.ivy)
    opts.grep_open_files = true
    opts.use_regex = true
    opts.search_dirs = array.map(
      dict.values(group:list()),
      function(state) return state end
    )
    grep(opts)
  end

  function default_action(prompt_bufnr)
    if remove then
      array.each(_.get_selected(prompt_bufnr), remove)
    else
      local sel = _.get_selected(prompt_bufnr)[1]
      local group = pool[sel]
      if not dict.isblank(group.buffer) then group:create_picker():find() end
    end
  end

  return _.new_picker(self:list(true), {
    default_action,
    { "n", "/", mod.grep },
    { "n", "x", mod.remove },
    { "n", "a", mod.add },
  }, {
    prompt_title = "Buffer group pool: " .. self.name,
  })
end

function Bufgroup.create_picker_for_buffer(bufnr, remover)
  exception.invalid_buffer:throw_unless(buffer.exists(bufnr), bufnr)

  if not user.bufgroup.BUFFER[bufnr] then return end

  local groups = dict.keys(user.bufgroup.BUFFER[bufnr].groups)
  if #groups == 1 then
    local group = Bufgroup.get(groups[1])
    if not group then return end
    local picker = group:create_picker(remover)
    if picker then return picker end
  end

  local _ = utils.telescope.load()
  local mod = _.create_actions_mod()

  local results = {
    results = groups,
    entry_maker = function(x)
      x = user.bufgroup.BUFFER[bufnr].groups[x]
      return {
        bufnr = bufnr,
        group = x.name,
        value = x,
        display = sprintf("%s @ %s", x.name, table.concat(x.pattern, " ")),
        ordinal = -1,
      }
    end,
  }

  local function remove(sel)
    local group = pool[sel.group]
    local connected = group.buffer
    if array.isblank(connected) then
      sprintf("Deleted buffer group: %s.%s", sel.pool, sel.group)
      group:delete()
    else
      group:create_picker(true):find()
    end
  end


  local function default_action(prompt_bufnr)
    if remover then
      array.each(
        _.get_selected(prompt_bufnr),
        remove
      )
    else
      local sel = _.get_selected(prompt_bufnr)[1][1]
      local group = user.bufgroup.BUFGROUP[sel]
      local picker = group:create_picker()
      if picker then picker:find() end
    end
  end

  function mod.remove(sel)
    remove(sel)
  end

  function mod.grep(sel)
    local group = pool[sel.group]
    local grep = require("telescope.builtin").grep_string
    local opts = copy(_.ivy)
    opts.grep_open_files = true
    opts.use_regex = true
    opts.search_dirs = array.map(
      dict.values(group:list()),
      function(state) return state end
    )
    grep(opts)
  end

  function mod.add(_)
    local pool = input "Buffer group pool name % "
    if #pool == 0 then return false end

    local group = input "Buffer group name % "
    if #group == 0 then return false end

    local pattern = input "Patterns to match (delim = ::) % "
    if #pattern == 0 then return false end
    pattern = pattern:split "%s*::%s*"

    Bufgroup(group, "BufRead", pattern, pool_name)
  end

  local title = remover 
    and '(Remover) Select buffer group'
    or 'Select buffer group'

  return _.new_picker(results, {
    default_action,
    { "n", "x", mod.remove },
  }, {
    prompt_title = title
  })
end

return Bufgroup
