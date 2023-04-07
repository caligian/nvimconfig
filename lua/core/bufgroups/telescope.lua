require "core.bufgroups.BufGroup"
require "core.bufgroups.defaults"

utils.telescope.load()

local _ = utils.telescope
local mod = _.create_actions_mod()

local function list_buffers(group)
  local exists = BufGroup.get(group)
  if not exists then return end
  exists:clean()
  local list = exists:list()
  if #list == 0 then return end

  return list
end

local function list_groups()
  local ks = Dict.keys(BufGroup.groups)
  if #ks == 0 then return end
  return ks
end

local function run_buffers_picker(group)
  local buffers = list_buffers(group)
  if not buffers then return end

  _.new(list_buffers(group), function(prompt_bufnr)
    local sel = _.get_selected(prompt_bufnr)[1][1]
    vim.cmd(":b " .. sel)

  end, { prompt_title = sprintf("BufGroup %s", group) }):find()
end

local function run_all_groups_picker()
  local groups = list_groups()
  if not groups then return end
  _.new(groups, function(prompt_bufnr)
    local sel = _.get_selected(prompt_bufnr)[1][1]
    run_buffers_picker(sel)
  end, {
    prompt_title = "All BufGroups",
  }):find()
end

local function run_groups_picker(pool)
  if not pool then return run_all_groups_picker() end

  if is_a.string(pool) then
    pool = user.bufgroups._pools[pool]
    if not pool then return end
  end

  local groups = pool:list()
  if not groups then return end
  _.new(Dict.keys(groups), function(prompt_bufnr)
    local group = _.get_selected(prompt_bufnr)[1][1]
    run_buffers_picker(group)
  end, {
    prompt_title = sprintf("BufgroupPool %s", pool.name),
  }):find()
end

local function run_pools_picker()
  local pools = Dict.keys(user.bufgroups._pools)
  if #pools == 0 then return end
  _.new(pools, function(prompt_bufnr)
    local sel = _.get_selected(prompt_bufnr)[1][1]
    run_groups_picker(user.bufgroups._pools[sel])
  end, {
    prompt_title = sprintf "All BufGroupPools",
  }):find()
end

K.bind({ noremap = true, leader = true }, {
  ".",
  function()
    local ok, value =
      pcall(vim.api.nvim_buf_get_var, vim.fn.bufnr(), "_bufgroup")
    if ok then run_buffers_picker(value) end
  end,
  "Show current group",
}, {
  ">",
  function()
    local ok, value =
      pcall(vim.api.nvim_buf_get_var, vim.fn.bufnr(), "_bufgrouppool")
    if ok then run_groups_picker(value) end
  end,
  "Show groups in current pool",
}, {
  '<tab><tab>',
  run_all_groups_picker,
  'Show all groups',
}, {
  '<tab>p',
  run_pools_picker,
  'Show all bufgrouppools',
})
