require "core.globals"
require "core.netrw"
require "core.option"

filetype.main()
bookmark.main()
repl.main()
buffergroup.main()
kbd.main()
au.main()

plugin.main()
user.plugins.colorscheme:setup()
user.plugins.statusline:setup()

vim.api.nvim_create_user_command('ReloadStatusline', function ()
  user.plugins.statusline:setup()
end, {})

vim.api.nvim_create_user_command('ReloadColorscheme', function ()
  user.plugins.colorscheme:setup()
end, {})

kbd.map('n', '<leader>hC', ':ReloadColorscheme<CR>', 'reload colorscheme')
kbd.map('n', '<leader>h=', ':ReloadStatusline<CR>', 'reload statusline')

if vim.fn.has('gui') then
  require('core.utils.font').main()
end

require 'core.defaults.commands'
