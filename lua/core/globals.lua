local function new_class(name)
    if not _G[name] then
        class[name]()
    end
end

new_class 'Keybinding'
new_class 'Package'
new_class 'REPL'
new_class 'Autocmd'

user.lang = user.lang or {}
user.pkg = user.pkg or Package
user.compile = user.compile or {}
user.lsp = user.lsp or {}
user.color = user.color or {}
user.autocmd = user.autocmd or Autocmd
user.kbd = user.kbd or Keybinding
user.shell = '/usr/bin/zsh'
user.colorscheme = 'solarized8_dark_low'
user.font = "UbuntuMono Nerd Font:h13"

builtin.require 'user.core.globals'
