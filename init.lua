-- goneovim-specific settings
pcall(function()
  vim.cmd [[
  noremap <space><tab><tab> :GonvimSidebarToggle<CR>
  noremap <space><tab>n :GonvimWorkspaceNew<CR>
  noremap <space><tab>f :GonvimWorkspaceNext<CR>
  noremap <space><tab>b :GonvimWorkspacePrevious<CR>
  noremap <space><tab>1 :GonvimWorkspaceSwitch 1<CR> 
  noremap <space><tab>2 :GonvimWorkspaceSwitch 2<CR>
  noremap <space><tab>3 :GonvimWorkspaceSwitch 3<CR>
  noremap <space><tab>4 :GonvimWorkspaceSwitch 4<CR>
  noremap <space><tab>5 :GonvimWorkspaceSwitch 5<CR>
  noremap <space><tab>6 :GonvimWorkspaceSwitch 6<CR>
  noremap <space><tab>7 :GonvimWorkspaceSwitch 7<CR>
  noremap <space><tab>8 :GonvimWorkspaceSwitch 8<CR>
  noremap <space><tab>9 :GonvimWorkspaceSwitch 9<CR>
  noremap <space><tab>0 :GonvimWorkspaceSwitch 10<CR>
  noremap <space>oM :GonvimMiniMap<CR>

  GonvimSmoothScroll
  GonvimLigatures
  ]]
end)

vim.o.autochdir = true
vim.o.showcmd = false
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
