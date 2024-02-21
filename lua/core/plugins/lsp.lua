return {
  setup = function()
    Filetype.setup_lsp_all()
  end,
  autocmds = {
    enable_c_lsp = {
      "Filetype",
      {
        pattern = { "c", "cpp" },
        callback = function(_)
          require("ccls").setup {
            lsp = { use_defaults = true },
          }
        end,
      },
    },
  },
}
