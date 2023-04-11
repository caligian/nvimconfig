local load_telescope = function()
  return {
    exists = req "telescope",
    pickers = req "telescope.pickers",
    actions = req "telescope.actions",
    action_state = req "telescope.actions.state",
    sorters = req "telescope.sorters",
    finders = req "telescope.finders",
    conf = utils.try_require("telescope.config", function(M)
      return M.values
    end),
    ivy = utils.try_require("telescope.themes", function(M)
      return table.merge(M.get_ivy(), {
        disable_devicons = true,
        previewer = false,
        extensions = {},
        layout_config = { height = 0.3 },
      })
    end),
  }
end

utils.telescope = {}
local M = utils.telescope

function M.load()
  local _ = load_telescope()
  for name, val in pairs(_) do
    M[name] = val
  end
  return M
end

function M.get_selected(bufnr, close)
  close = close == nil and true or close
  local _ = load_telescope()
  local picker = _.action_state.get_current_picker(bufnr)
  if close then
    _.actions.close(bufnr)
  end
  local nargs = picker:get_multi_selection()
  if #nargs > 0 then
    return nargs
  end

  return { _.action_state.get_selected_entry() }
end

function M.new(items, mappings, opts)
  local _ = load_telescope()

  opts = opts or {}

  -- If opts.finder is missing, then only items will be used
  if not opts.finder and items then
    opts.finder = _.finders.new_table(items)
  end

  opts.sorter = opts.sorter or _.sorters.get_fzy_sorter()

  if mappings then
    mappings = table.tolist(mappings)
    local attach_mappings = opts.attach_mappings
    opts.attach_mappings = function(prompt_bufnr, map)
      if mappings then
        local default = mappings[1]
        if default then
          _.actions.select_default:replace(function()
            default(prompt_bufnr)
          end)
        end
        table.each(table.rest(mappings), function(x)
          map(unpack(x))
        end)
      end
      if attach_mappings then
        attach_mappings(prompt_bufnr, map)
      end
      return true
    end
  end
  return _.pickers.new(_.ivy, opts)
end

M.new_picker = M.new

function M.create_actions_mod(no_close)
  return setmetatable({}, {
    __newindex = function(self, name, f)
      local _ = load_telescope()
      rawset(self, name, function(bufnr)
        table.each(M.get_selected(bufnr, no_close), function(sel)
          return f(sel, bufnr)
        end)
      end)
    end,
  })
end
