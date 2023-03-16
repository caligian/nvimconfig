user.plugins.ssr = {
  config = {
    border = "rounded",
    min_width = 50,
    min_height = 5,
    max_width = 120,
    max_height = 25,
    keymaps = {
      close = "q",
      next_match = "n",
      prev_match = "N",
      replace_confirm = "<cr>",
      replace_all = "<leader><cr>",
    },
  },
}

req "user.plugins.ssr"
require("ssr").setup(user.plugins.ssr.config)
vim.keymap.set({ "n", "x" }, "<leader>%", function() require("ssr").open() end)
