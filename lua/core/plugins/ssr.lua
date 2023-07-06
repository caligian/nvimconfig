local ssr = plugin.get 'ssr'
ssr.config = {
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
}

ssr.mappings = {
    ssr = {
        "nx",
        "<leader>%",
        function()
            require("ssr").open()
        end,
        { desc = "Structural editing", name = "ssr" },
    },
}

function ssr:setup()
  require("ssr").setup(self.config)
end
