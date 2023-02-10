local data_dir = vim.fn.stdpath('data')

user.option = {
  o = {
    cursorline = true,
    updatetime = 300,
    foldenable = false,
    timeoutlen = 350,
    completeopt = 'menu,menuone,noselect',
    mouse = 'a',
    history = 1000,
    ruler = true,
    autochdir = true,
    showcmd = true,
    wildmode = 'longest,list,full',
    wildmenu = true,
    termguicolors = true,
    laststatus = 2,
    mousefocus = true,
    shell = '/usr/bin/zsh',
    backspace = 'indent,eol,start',
    number = true,
    tabstop = 4,
    shiftwidth = 4,
    expandtab = true,
    foldmethod = 'indent',
    inccommand = 'split',
    background = 'dark',
    backupdir = data_dir .. '/temp/backups',
    directory = data_dir .. '/temp/tmp',
    undodir = data_dir .. '/temp/undo',
  },
  g = {
    mapleader = ' ',
    maplocalleader = ',',
    netrw_banner = 0,
  },
}

V.require('user.option')

local font = user.font:gsub(' ', '\\ ')
vim.cmd('set guifont=' .. font)

for t, opts in pairs(user.option) do
  for k, v in pairs(opts) do
    vim[t][k] = v
  end
end
