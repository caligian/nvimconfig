builtin.makepath(user, 'lsp')
builtin.makepath(user, 'compiler')
builtin.makepath(user, 'pkg')
builtin.makepath(user, 'autocmd')
builtin.makepath(user, 'repl')
builtin.makepath(user, 'color')
builtin.makepath(user, 'kbd')
builtin.makepath(user, 'lsp')

user.shell = '/usr/bin/zsh'
user.colorscheme = 'OceanicNext'
user.font = "UbuntuMono Nerd Font:h13"

pcall(require, 'user.core.globals')

vim.o.guifont = user.font
