plugin.ultisnips = {
  config = {
    UltiSnipsExpandSnippet = "<tab>",
    UltiSnipsJumpForwardTrigger = "<C-j>",
    UltiSnipsJumpBackwardTrigger = "<C-k>",
    UltiSnipsEditSplit = "tabdo",
    UltiSnipsSnippetDirectories = { "UltiSnips", "snips" },
  },

  setup = function(self)
    for k, v in pairs(self.config) do
      vim.g[k] = v
    end
  end
}
