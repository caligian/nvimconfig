user.plugins.neorg = {
  MODE = 'norg',
  config = {
    load = {
      ["core.defaults"] = {},
      ['core.export'] = {},
      ['core.norg.concealer'] = {},
      ['core.norg.manoeuvre'] = {},
      ['core.integrations.treesitter'] = {},

      ['core.keybinds'] = {
        config = {
          default_keybinds = false,
          hook = function (kbd)
            kbd.map('norg', 'n', '<leader>mm', function ()
              local mode = user.plugins.neorg.MODE
              if mode == 'traverse-heading' then
                mode = 'norg'
              else
                mode = 'traverse-heading'
              end

              user.plugins.neorg.MODE = mode

              vim.cmd(':Neorg mode ' .. mode)
            end)

            kbd.map('norg', 'n', '<leader>me', function ()
              vim.cmd(':Neorg export to-file ' .. vim.fn.input('Export as % '))
            end)
          end
        }
      },

      ['core.mode'] = {},

      ['core.export.markdown'] = {
        config = {
          extensions = 'all',
          extension = 'md',
        }
      },

      ['core.norg.completion'] = {
        config = {
          engine = 'nvim-cmp',
          name = '[Neorg]',
        }
      },

      ["core.norg.dirman"] = {
        config = {
          workspaces = {
            work = "~/Work",
            college = "~/Work/College",
            iigl = "~/Work/IIGL",
          },
        },
      },
    },
  },
}

req "user.plugins.neorg"
require("neorg").setup(user.plugins.neorg.config)
