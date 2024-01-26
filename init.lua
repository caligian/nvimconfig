vim.o.autochdir = true
vim.o.showcmd = false
vim.opt.shortmess:append "I"

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
  lazy = true,
  setup_user_dirs = true,
  setup_luarocks = true,
}

if Path.exists(user.paths.logs) then
  Path.delete(user.paths.logs)
end

local lsp_logs = Path.join(vim.fn.stdpath "state", "lsp.log")
if Path.exists(lsp_logs) then
  Path.rm(lsp_logs)
end

nvim.create.autocmd({ "BufDelete" }, {
  pattern = "*",
  callback = function(opts)
    if user.buffers[opts.buf] then
      user.buffers[opts.buf] = nil
    end
  end,
})

-- Load the framework
require "core"
