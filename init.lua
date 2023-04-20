vim.o.autochdir = true
vim.o.showcmd = false
vim.opt.shortmess:append 'I'
vim.keymap.set("n", "<space>fv", ":w <bar> :luafile %<CR>", { noremap = true })
vim.keymap.set("n", "<space>fs", ":w<CR>", { noremap = true })
vim.keymap.set("n", "<space>fp", ":e ~/nvimconfig<CR>", { noremap = true })

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*.lua",
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
  end,
})

-- Bootstrap with requisite rocks and lazy.nvim
require "bootstrap"

-- Load the framework
require "core"
