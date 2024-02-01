local data_dir = vim.fn.stdpath "data"

user.option = {
  o = {
    swapfile = false,
    scrolloff = 5,
    number = true,
    incsearch = true,
    hidden = false,
    relativenumber = true,
    showcmd = true,
    splitright = true,
    splitbelow = true,
    cursorline = false,
    updatetime = 300,
    swapfile = false,
    foldenable = false,
    timeoutlen = 500,
    showtabline = true,
    completeopt = "menu,menuone,noselect",
    mouse = "a",
    history = 1000,
    autochdir = true,
    ruler = true,
    wildmode = "list:longest",
    wildmenu = true,
    termguicolors = true,
    laststatus = 3,
    mousefocus = true,
    shell = "/bin/bash",
    backspace = "indent,eol,start",
    tabstop = 2,
    shiftwidth = 2,
    expandtab = true,
    foldmethod = "indent",
    inccommand = "split",
    background = "dark",
    guifont = "Liberation Mono:h11",
    virtualedit = "onemore",
  },
  g = {
    mapleader = " ",
    maplocalleader = ",",
    neovide_cursor_vfx_mode = "sonicboom",
    netrw_keepdir = 0,
  },
}


  for t, opts in pairs(user.option) do
    for k, v in pairs(opts) do
      vim[t][k] = v
    end
  end
