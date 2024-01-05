require "core.globals"
require "core.netrw"
require "core.option"

Filetype.main()
Bookmark.main()
REPL.main()
BufferGroup.main()
Autocmd.main()
Plugin.main()

vim.api.nvim_create_user_command("ReloadStatusline", function()
  user.plugins.statusline:setup()
end, {})

vim.api.nvim_create_user_command("ReloadColorscheme", function()
  user.plugins.colorscheme:setup()
end, {})

if vim.fn.has "gui" then
  require("core.utils.font").main()
end

Kbd.map("n", "<leader>hC", ":ReloadColorscheme<CR>", "reload colorscheme")
Kbd.map("n", "<leader>h=", ":ReloadStatusline<CR>", "reload statusline")

vim.defer_fn(function ()
  require "core.defaults.commands"
  Kbd.main()
end, 100)
  
