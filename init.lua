vim.o.foldenable = false
vim.o.timeoutlen = 350
vim.o.completeopt = "menu,menuone,noselect"
vim.o.mouse = "a"
vim.o.history = 1000
vim.o.ruler = true
vim.o.autochdir = true
vim.o.showcmd = true
vim.o.wildmode = "longest,list,full"
vim.o.wildmenu = true
vim.o.termguicolors = true
vim.o.laststatus = 2
vim.o.mousefocus = true
vim.o.shell = "/usr/bin/zsh"
vim.o.backspace = "indent,eol,start"
vim.o.number = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.foldmethod = "indent"
vim.o.inccommand = 'split'
vim.o.background = 'dark'
vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.o.guifont = 'Hack Nerd Font:h13'
vim.o.laststatus = 2

local data_dir = vim.fn.stdpath('data')
vim.o.backupdir = data_dir .. '/temp/backups'
vim.o.directory = data_dir .. '/temp/tmp'
vim.o.undodir = data_dir .. '/temp/undo'

local config_dir = vim.fn.stdpath('config')
package.path = package.path .. ';' .. config_dir .. '/luarocks/share/lua/5.1/?.lua'
package.path = package.path .. ';' .. config_dir .. '/luarocks/share/lua/5.1/?/init.lua'
package.path = package.path .. ';' .. config_dir .. '/luarocks/share/lua/5.1/?/?.lua'
package.cpath = package.cpath .. ';' .. config_dir .. '/luarocks/share/lua/5.1/?.so'
package.cpath = package.cpath .. ';' .. config_dir .. '/luarocks/lib/lua/5.1/?.so'

-- ~/.nvim is the user configuration directory
-- ~/.nvim/lua is added to the path
-- You should put your configuration in ~/.nvim/lua/user as your configs can be required by require 'user.<...>'
package.path = package.path .. ';' .. os.getenv('HOME') .. '/.nvim/lua/?/init.lua'

-- Load the additional framework
require 'core'
