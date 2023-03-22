local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

return {
  create_actions = function()
    return setmetatable({}, {
      __newindex = function(self, name, f)
        rawset(self, name, function(bufnr)
          local picker = action_state.get_current_picker(bufnr)
          local nargs = picker:get_multi_selection()
          if #nargs > 0 then
            for _, value in ipairs(nargs) do
              f(value)
            end
          else
            local entry = action_state.get_selected_entry()
            if entry then f(entry) end
          end
          actions.close(bufnr)
        end)
      end,
    })
  end,
}
