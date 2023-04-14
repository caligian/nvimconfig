-- require "core.bufgroups.Bufgroup"
require 'core.bufgroups.Bufgroup'

if not BufgroupPool then class "BufgroupPool" end
BufgroupPool.POOLS = BufgroupPool.POOLS or {}
local Pool = BufgroupPool

function Pool:init(name)
  self.name = name
  self.groups = {}
  BufgroupPool.POOLS[self.name] = self
end

-- @param group Name of the group. The group will be prefixed by <pool-name>.group
function Pool:add(group, event, pattern)
  validate {
    group_name = {'string', group},
    event = {is {'string', 'table'}, event},
    pattern = {is {'string', 'table'}, pattern}
  }

  local bufgroup = Bufgroup(group, event, pattern, self.name)
  local group = self.name .. '.' .. group 
  self.groups[group] = bufgroup
  bufgroup:enable()

  return self.groups[group]
end

function Pool:remove(group, bufnr)
  group = self.groups[isa("string", group)]

  if group and bufnr then
    group:delete(bufnr)
  else
    self.groups[group] = nil
  end

  return group
end

function Pool:list(telescope)
  if dict.isblank(self.groups) then
    return
  elseif not telescope then
    local out = {}
    for group, value in pairs(self.groups) do
      out[group] = value:list()
    end

    return out
  end

  return {
    results = dict.keys(self.groups),
    entry_maker = function(entry)
      local group = self.groups[entry]
      return {
        value = entry,
        display = sprintf("%s @ %s", entry, table.concat(group.pattern, " :: ")),
        ordinal = -1,
        group = entry,
        pool = group.pool,
        pattern = group.event,
        event = group.pattern,
      }
    end,
  }
end

function Pool:register(group, callback_id, callback)
  Bufgroup.get(self.name, group):register(callback_id, callback)
end

function Pool:create_picker()
  local _ = utils.telescope.load()
  local T = utils.telescope
  local mod = T.create_actions_mod()
  local input = vim.fn.input

  function mod.remove(sel)
    local group = Bufgroup.get(sel.pool, sel.group)
    if group then
      group:delete()
    end
    sprintf("Deleted buffer group: %s.%s", sel.pool, sel.group)
  end

  function mod.add(_)
    local pool = input "Pool name % "
    if #pool == 0 then
      return false
    end

    local group = input "Buffer group name % "
    if #group == 0 then
      return false
    end

    local pattern = input "Patterns to match (delim = ::) % "
    if #pattern == 0 then
      return false
    end
    pattern = pattern:split "%s*::%s*"

    Bufgroup(group, "BufRead", pattern, pool)
  end

  function mod.grep(sel)
    local group = Bufgroup.get(sel.pool, sel.group)
    local grep = require("telescope.builtin").grep_string
    local opts = copy(_.ivy)
    opts.grep_open_files = true
    opts.use_regex = true
    opts.search_dirs = array.map(dict.values(group:list()), function(state)
      return state.bufname
    end)
    grep(opts)
  end

  return _.new_picker(self:list(true), {
    function(bufnr)
      local sel = _.get_selected(bufnr)[1]
      local picker = Bufgroup.get(sel.pool, sel.group):create_picker()
      if picker then picker:find() end
    end,
    { "n", "/", mod.grep },
    { "n", "x", mod.remove },
    { "n", "a", mod.add },
  }, {
    prompt_title = "Buffer group pool: " .. self.name,
  })
end

function Pool.get(name, assrt)
  local pool = Pool.POOLS[name]
  if assrt then
    assert(pool, "invalid pool name " .. name .. " given")
  end
  return pool
end

function Pool.create_picker_for_buffer(bufnr)
  bufnr = isa('number', bufnr)
  assert(buffer.exists(bufnr), 'expected valid buffer, got ' .. bufnr)
  assert(Bufgroup.BUFFERS[bufnr], 'expected grouped buffer')

  local groups = dict.keys(Bufgroup.BUFFERS[bufnr].groups)
  pp(groups)
  if #groups == 1 then
    local group = Bufgroup.get(nil, groups[1], true)
    return group:create_picker()
  end

  local _ = utils.telescope.load()
  local mod = _.create_actions_mod()

  local results =  {
    results = groups,
    entry_maker = function (x)
      x = Bufgroup.BUFGROUPS[x]
      return {
        bufnr = bufnr,
        group = x.name,
        value = x,
        display = sprintf('%s @ %s', x.name, table.concat(x.pattern, " ")),
        ordinal = -1,
      }
    end
  }

  local default_action = function(prompt_bufnr)
    local sel = _.get_selected(prompt_bufnr)[1]
    local x = sel.value
    local picker = x:create_picker()
    if not picker then return utils.nvimerr('group is empty ' .. x.name) end
    picker:find()
  end

  function mod.remove(sel)
    sel.value:remove(sel.bufnr)
  end

  return _.new_picker(
    results, 
    {
      default_action,
      {'n', 'x', mod.remove}
    },
    {
      prompt_title = 'Select buffer group'
    }
  )
end

function Pool.create_main_picker(opts)
  local ls = table.keys(BufgroupPool.POOLS)
  if array.isblank(ls) then return end
  local _ = utils.telescope.load()

  local function default_action(prompt_bufnr)
    local sel = _.get_selected(prompt_bufnr)[1]
    local pool = Pool.get(sel[1])
    if not pool then return end
    local picker = pool:create_picker()
    if picker then picker:find() end
  end

  return _.new_picker(
    ls,
    default_action,
    {prompt_title = 'Buffer group pools'}
  )
end
