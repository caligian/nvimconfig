K.bind({ noremap = true, leader = true }, {
  "hC",
  ":ContextToggleWindow<CR>",
  "Enable context",
})

vim.g.context_presenter = "nvim-float"
vim.g.context_max_height = 15

req "user.plugins.context"
