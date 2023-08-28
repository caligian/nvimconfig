vim.o.autochdir = true
vim.o.showcmd = false
vim.opt.shortmess:append 'I'
vim.keymap.set("n", "<space>fv", ":w <bar> :luafile %<CR>", { noremap = true })
vim.keymap.set("n", "<space>fs", ":w<CR>", { noremap = true })
vim.keymap.set("n", "<space>fp", ":e ~/nvimconfig<CR>", { noremap = true })

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*.lua",
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
  end,
})

vim.api.nvim_create_autocmd('BufEnter', {
    pattern = '*',
    callback = function (args)
        local last_buffer = vim.g.recent_buffer 
        vim.g.recent_buffer = args.buf

        if last_buffer then
            vim.keymap.set('n', '<space>bl', ':b ' .. last_buffer .. '<CR>', {buffer = args.buf})
        end
    end
})

-- Bootstrap with requisite rocks and lazy.nvim
require "bootstrap"

file.delete(path.join(os.getenv('HOME'), '.local', 'share', 'nvim', 'messages'))

-- Load the framework
require 'core.utils'
require "core"
