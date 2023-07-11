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
    cursorline = true,
    updatetime = 300,
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
    tabstop = 4,
    shiftwidth = 4,
    expandtab = true,
    foldmethod = "indent",
    inccommand = "split",
    background = "dark",
    guifont = "Liberation Mono:h12",
  },
  g = {
    mapleader = " ",
    maplocalleader = "-",
    neovide_cursor_vfx_mode = "sonicboom",
    netrw_keepdir = 0,
  },
}

req "user.option"

for t, opts in pairs(user.option) do
  for k, v in pairs(opts) do
    vim[t][k] = v
  end
end
