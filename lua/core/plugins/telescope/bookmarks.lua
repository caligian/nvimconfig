local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local _actions = {
  open = function(prompt_bufnr)
    local sel = action_state.get_selected_entry()[1]
    Bookmarks.open(sel)
  end,

  remove = function(prompt_bufnr)
    local picker = action_state.get_current_picker(prompt_bufnr)
    local sel = picker:get_multi_selection()
    if #sel > 0 then
      table.each(sel, Bookmarks.remove)
    else
      Bookmarks.remove(action_state.get_selected_entry()[1])
    end
    actions.close(prompt_bufnr)
  end,
}

local function run_picker()
  local bookmarks = Bookmarks.load()

  pickers
    .new(user.plugins.telescope.config, {
      prompt_title = sprintf "Bookmarks",
      finder = finders.new_table { results = table.keys(bookmarks) },
      sorter = conf.generic_sorter(),
      attach_mappings = function(prompt_bufnr, map)
        map("n", "x", _actions.remove)
        map("n", "<CR>", _actions.open)
        map("i", "<CR>", _actions.open)

        return true
      end,
    })
    :find()
end

K.noremap("n", "<C-c>bb", run_picker, "Telescope bookmarks")
