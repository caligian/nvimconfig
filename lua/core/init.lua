require "core.globals"
require "core.netrw"
require "core.option"

Filetype.main()
Bookmark.main()
REPL.main()
BufferGroup.main()

vim.defer_fn(function ()
  Kbd.main()
end, 200)

Autocmd.main()
Plugin.main()

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

vim.defer_fn(function ()
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

  require "core.defaults.commands"
end, 100)

if vim.fn.has "gui" then
  require("core.utils.font").main()
end
