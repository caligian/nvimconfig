vim.o.autochdir = true
vim.o.showcmd = false
vim.opt.shortmess:append "I"
vim.opt.formatoptions:remove {'r', 'o'}
vim.o.shell = 'bash'
vim.o.shellcmdargs = '-l -c'

vim.keymap.set("n", "<space>fv", ":w <bar> :luafile %<CR>", { noremap = true, desc = "source file" })

vim.keymap.set("n", "<space>fs", ":w<CR>", { noremap = true, desc = "save file" })

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*.lua",
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
  end,
})

require "nvim-utils" {
  lazy = {enable = true},
  luarocks = {enable = true},
}

if Path.exists(user.log_path) then
  Path.delete(user.log_path)
end

-- Load the framework
require "core"
