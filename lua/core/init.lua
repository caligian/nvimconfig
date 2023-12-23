require "core.globals"
require "core.netrw"
require "core.option"

Filetype.main()
Bookmark.main()
REPL.main()
BufferGroup.main()
Kbd.main()
Autocmd.main()
Plugin.main()

user.plugins.colorscheme:setup()
user.plugins.statusline:setup()

vim.api.nvim_create_user_command(
  "ReloadStatusline",
  function()
    user.plugins.statusline:setup()
  end,
  {}
)

vim.api.nvim_create_user_command(
  "ReloadColorscheme",
  function()
    user.plugins.colorscheme:setup()
  end,
  {}
)

Kbd.map(
  "n",
  "<leader>hC",
  ":ReloadColorscheme<CR>",
  "reload colorscheme"
)
Kbd.map(
  "n",
  "<leader>h=",
  ":ReloadStatusline<CR>",
  "reload statusline"
)

if vim.fn.has "gui" then
  require("core.utils.font").main()
end

require "core.defaults.commands"
