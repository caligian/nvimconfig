local data_dir = vim.fn.stdpath "data"

user.option = {
  o = {
    scrolloff = 5,
    number = true,
    incsearch = false,
    hidden = false,
    relativenumber = true,
    showcmd = true,
    splitright = true,
    splitbelow = true,
    cursorline = false,
    updatetime = 300,
    foldenable = true,
    timeoutlen = 350,
    showtabline = true,
    completeopt = "menu,menuone,noselect",
    mouse = "a",
    history = 1000,
    autochdir = true,
    ruler = true,
    wildmode = "longest:full,full,list",
    wildmenu = true,
    termguicolors = true,
    laststatus = 2,
    mousefocus = true,
    shell = "/usr/bin/zsh",
    backspace = "indent,eol,start",
    tabstop = 4,
    shiftwidth = 4,
    expandtab = true,
    foldmethod = "indent",
    inccommand = "split",
    background = "dark",
  },
  g = {
    mapleader = " ",
    maplocalleader = ",",
  },
}

req "user.option"

for t, opts in pairs(user.option) do
  for k, v in pairs(opts) do
    vim[t][k] = v
  end
end
