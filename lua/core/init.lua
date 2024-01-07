require "core.globals"
require "core.netrw"
require "core.option"

Filetype.main()
Plugin.main()
BufferGroup.main()
Autocmd.main()

Bookmark.main()

require "core.defaults.commands"

vim.api.nvim_create_user_command("ReloadStatusline", function()
  user.plugins.statusline:setup()
end, {})

vim.api.nvim_create_user_command("ReloadColorscheme", function()
  user.plugins.colorscheme:setup()
end, {})
vim.defer_fn(function()
  REPL.main()
  Kbd.map("n", "<leader>hC", ":ReloadColorscheme<CR>", "reload colorscheme")
  Kbd.map("n", "<leader>h=", ":ReloadStatusline<CR>", "reload statusline")
  Kbd.main()
end, 50)
