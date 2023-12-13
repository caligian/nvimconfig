local T = module()

function T:__call()
  return dict.merge(self, {
    exists = require "telescope",
    pickers = require "telescope.pickers",
    actions = require "telescope.actions",
    action_state = require "telescope.actions.state",
    sorters = require "telescope.sorters",
    finders = require "telescope.finders",
    conf = require("telescope.config").values,
    theme = dict.merge(
      require("telescope.themes").get_dropdown(),
      {
        disable_devicons = true,
        previewer = false,
        extensions = {},
        layout_config = {
          height = 0.8,
          width = 0.9,
        },
      }
    ),
  })
end

function T:create_picker(items, mappings, opts)
  opts = opts or {}
  local overrides = self

  -- If opts.finder is missing, then only items will be used
  if not opts.finder and items then
    opts.finder = overrides.finders.new_table(items)
  end

  opts.sorter = opts.sorter
    or overrides.sorters.get_fzy_sorter()

  if mappings then
    mappings = tolist(mappings)

    opts.attach_mappings = function(prompt_bufnr, map)
      if mappings then
        local default = mappings[1]

        if default then
          overrides.actions.select_default:replace(
            function()
              default(self:selected(prompt_bufnr))
            end
          )
        end

        list.each(list.rest(mappings), function(x)
          local mode, ks, cb = unpack(x)
          local function callback()
            cb(self:selected(prompt_bufnr))
          end
          map(mode, ks, callback)
        end)
      end

      return true
    end
  end

  return overrides.pickers.new(self.theme, opts)
end

function T:selected(bufnr)
  local overrides = self
  local picker =
    overrides.action_state.get_current_picker(bufnr)
  if picker then
    overrides.actions.close(bufnr)

    local nargs = picker:get_multi_selection()

    if #nargs > 0 then
      return nargs
    end

    return { overrides.action_state.get_selected_entry() }
  end
end

function load_telescope()
  return T()
end

return T
