vim.o.foldenable = false
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
vim.o.shell = "/bin/bash"
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
vim.o.guifont = 'DejaVuSans Mono:h15'
vim.o.laststatus = 2

-- Fixing ESC in terminal
vim.cmd('tnoremap <Esc> <C-\\><C-n>')

-- Source lua buffer
vim.api.nvim_set_keymap('n', '<leader>fv', '', {
    noremap = true,
    callback = function ()
        local s = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        s = table.concat(s, "\n")
        local f, err = loadstring(s)
        if f then
            f()
        else
            print(err)
        end
    end
})

-- File keybindings
vim.cmd('noremap <leader>fs :w<CR>')
vim.cmd('noremap <leader>fr :e!<CR>')
vim.cmd('noremap <leader>fV :source %<CR>')

function join_path(...) return table.concat({...}, "/") end
local data_dir = vim.fn.stdpath('data')
vim.o.backupdir = join_path(data_dir, 'temp', 'backups')
vim.o.directory = join_path(data_dir, 'temp', 'tmp')
vim.o.undodir = join_path(data_dir, 'temp', 'undo')

local config_dir = vim.fn.stdpath('config')
package.path = package.path .. ';' .. config_dir .. '/luarocks/share/lua/5.1/?.lua'
package.path = package.path .. ';' .. config_dir .. '/luarocks/share/lua/5.1/?/init.lua'
package.path = package.path .. ';' .. config_dir .. '/luarocks/share/lua/5.1/?/?.lua'
package.cpath = package.cpath .. ';' .. config_dir .. '/luarocks/share/lua/5.1/?.so'
package.cpath = package.cpath .. ';' .. config_dir .. '/luarocks/lib/lua/5.1/?.so'

-- Load the additional framework
require 'core'
