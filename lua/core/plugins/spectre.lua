local spectre = {}

spectre.config = {}

spectre.autocmds = {
  disable_treesitter = {
    "FileType",
    {
      pattern = "spectre_panel",
      callback = function()
        vim.cmd ":TSBufDisable highlight"
      end,
    },
  },
}

spectre.mappings = {
  open_spectre = {
    "n",
    "<leader>%",
    '<cmd>lua require("spectre").toggle()<CR>',
    { desc = "open nvim-spectre", noremap = true },
  },
}

function spectre:setup()
  require("spectre").setup(self.config)
end

return spectre
