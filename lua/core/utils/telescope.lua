local load_telescope = function(override)
  local opts = dict.merge({
    exists = require "telescope",
    pickers = require "telescope.pickers",
    actions = require "telescope.actions",
    action_state = require "telescope.actions.state",
    sorters = require "telescope.sorters",
    finders = require "telescope.finders",
    conf = utils.try_require(
      "telescope.config",
      function(M) return M.values end
    ),
    ivy = utils.try_require(
      "telescope.themes",
      function(M)
        return dict.merge(M.get_dropdown(), {
          disable_devicons = true,
          previewer = false,
          extensions = {},
          layout_config = {
            height = 0.8,
            width = 0.9,
          },
        })
      end
    ),
  }, override or {})

  return opts
end

utils.telescope = {}
local M = utils.telescope

function M.load(override)
  local _ = load_telescope(override)
  for name, val in pairs(_) do
    M[name] = val
  end
  return M
end

function M.get_selected(bufnr, close)
  if close == nil then close = true end

  local _ = load_telescope()
  local picker = _.action_state.get_current_picker(bufnr)
  if close then _.actions.close(bufnr) end
  local nargs = picker:get_multi_selection()

  if #nargs > 0 then return nargs end
  return { _.action_state.get_selected_entry() }
end

M.selected = M.get_selected

function M.new(items, mappings, opts)
  local _ = load_telescope()

  opts = opts or {}

  -- If opts.finder is missing, then only items will be used
  if not opts.finder and items then opts.finder = _.finders.new_table(items) end

  opts.sorter = opts.sorter or _.sorters.get_fzy_sorter()

  if mappings then
    mappings = array.tolist(mappings)
    local attach_mappings = opts.attach_mappings
    opts.attach_mappings = function(prompt_bufnr, map)
      if mappings then
        local default = mappings[1]
        if default then
          _.actions.select_default:replace(function() default(prompt_bufnr) end)
        end
        array.each(array.rest(mappings), function(x) map(unpack(x)) end)
      end
      if attach_mappings then attach_mappings(prompt_bufnr, map) end
      return true
    end
  end
  return _.pickers.new(_.ivy, opts)
end

M.new_picker = M.new
M.create_picker = M.new
M.run_picker = function(...) return M.create_picker(...):find() end

function M.create_actions_mod(no_close)
  return setmetatable({}, {
    __newindex = function(self, name, f)
      local _ = load_telescope()
      rawset(self, name, function(bufnr)
        array.each(
          M.get_selected(bufnr, no_close),
          function(sel) return f(sel, bufnr) end
        )
      end)
    end,
  })
end

--[[
-- spec
{
  {<desc>, <callback>},
  ...
}
--]]
function M.create_menu(title, spec)
  return M.create_picker({
    results = spec,
    entry_maker = function(entry)
      return {
        value = entry[1],
        display = entry[1],
        ordinal = -1,
        callback = entry[2],
      }
    end,
  }, function(prompt_bufnr)
    local sel = M.get_selected(prompt_bufnr)[1]
    sel.callback(sel)
  end, {
    prompt_title = title,
  })
end

M.menu = M.create_menu

return M
