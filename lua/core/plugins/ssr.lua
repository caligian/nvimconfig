plugin.ssr = {
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

  kbd = {
    {
      "nx",
      "<leader>%",
      function()
        require("ssr").open()
      end,
      { desc = "Structural editing", name = "ssr" },
    },
  },

  on_attach = function(self)
    require("ssr").setup(self.config)
  end,
}
