local load_telescope = function()
  return {
    exists = req "telescope",
    pickers = req "telescope.pickers",
    actions = req "telescope.actions",
    action_state = req "telescope.actions.state",
    sorters = req "telescope.sorters",
    finders = req "telescope.finders",
    conf = utils.try_require(
      "telescope.config",
      function(M) return M.values end
    ),
    ivy = utils.try_require(
      "telescope.themes",
      function(M)
        return table.merge(M.get_ivy(), {
          disable_devicons = true,
          previewer = false,
          extensions = {},
          layout_config = { height = 0.3 },
        })
      end
    ),
  }
end

utils.telescope = setmetatable({}, {
  __index = function(self, k)
    local _ = load_telescope()
    if _.exists then 
      return rawget(self, k) 
    else
      error('telescope.nvim has not been loaded yet')
    end
  end,
})

local M = utils.telescope

function M.new(items, mappings, opts)
  local _ = load_telescope()

  opts = opts or {}

  -- If opts.finder is missing, then only items will be used
  if not opts.finder and items then opts.finder = _.finders.new_table(items) end

  opts.sorter = opts.sorter or _.sorters.get_fzy_sorter()

  if mappings then
    local attach_mappings = opts.attach_mappings
    opts.attach_mappings = function(prompt_bufnr, map)
      if mappings then
        local default = mappings[1]
        _.actions.select_default:replace(function()
          _.actions.close(prompt_bufnr)
          local sel = _.action_state.get_selected_entry()
          default(sel)
        end)

        mappings = table.rest(mappings)
        table.each(mappings, function(x)
          local sel = _.action_state.get_selected_entry()
          local callback = x[3]
          x[3] = function(_prompt_bufnr) callback(sel, _prompt_bufnr) end
          map(unpack(x))
        end)
      end
      if attach_mappings then attach_mappings(prompt_bufnr, map) end
      return true
    end
  end
  return _.pickers.new(_.ivy, opts)
end

function M.create_actions_mod()
  return setmetatable({}, {
    __newindex = function(self, name, f)
      local _ = load_telescope()
      rawset(self, name, function(bufnr)
        local picker = _.action_state.get_current_picker(bufnr)
        local nargs = picker:get_multi_selection()
        if #nargs > 0 then
          for _, value in ipairs(nargs) do
            f(value)
          end
        else
          local entry = _.action_state.get_selected_entry()
          if entry then f(entry) end
        end
        _.actions.close(bufnr)
      end)
    end,
  })
end
