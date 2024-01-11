user.telescope = module()
local T = user.telescope

function T:__call()
  if self.exists then
    return self
  end

  self.exists = require "telescope"
  self.pickers = require "telescope.pickers"
  self.actions = require "telescope.actions"
  self.action_state = require "telescope.actions.state"
  self.sorters = require "telescope.sorters"
  self.finders = require "telescope.finders"
  self.conf = require("telescope.config").values
  self.theme = dict.merge(require("telescope.themes").get_ivy(), {
    {
      disable_devicons = false,
      previewer = false,
      layout_config = { height = 0.3 },
    },
  }, { dict.filter(T, function(key, _)
    return key ~= "__call"
  end) })

  return self
end

function T:selected(bufnr, many)
  local picker = self.action_state.get_current_picker(bufnr)

  if picker then
    self.actions.close(bufnr)

    if many then
      local nargs = picker:get_multi_selection()
      if #nargs > 0 then
        return nargs
      end

      return { self.action_state.get_selected_entry() }
    end

    return self.action_state.get_selected_entry()
  end
end

function T:create_picker(items, mappings, opts)
  opts = opts or {}

  -- If opts.finder is missing, then only items will be used
  if not opts.finder and items then
    opts.finder = self.finders.new_table(items)
  end

  opts.sorter = opts.sorter or self.sorters.get_fzy_sorter()

  if mappings then
    mappings = to_list(mappings)

    opts.attach_mappings = function(prompt_bufnr, map)
      if mappings then
        local default = mappings[1]

        self.actions.select_default:replace(function()
          default(prompt_bufnr)
        end)

        for i = 2, #mappings do
          map(unpack(mappings[i]))
        end
      end

      return true
    end
  end

  return self.pickers.new(self.theme, opts)
end
