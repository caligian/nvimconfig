local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local colors = user.colorscheme.colorscheme

local function run_picker()
  pickers
    .new(user.plugins.telescope.config, {
      prompt_title = sprintf("colorscheme (current: %s)", vim.g.colors_name or "default"),
      finder = finders.new_table { results = dict.keys(colors) },
      sorter = conf.generic_sorter(),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local sel = action_state.get_selected_entry()[1]
          user.colorscheme.apply(sel)
        end)
        return true
      end,
    })
    :find()
end

K.noremap("n", "<leader>hc", run_picker, "Set colorscheme")
