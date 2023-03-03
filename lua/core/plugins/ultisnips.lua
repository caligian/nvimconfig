user.plugins["ultisnips"] = {
  config = {
    UltiSnipsExpandSnippet = "<tab>",
    UltiSnipsJumpForwardTrigger = "<C-j>",
    UltiSnipsJumpBackwardTrigger = "<C-k>",
    UltiSnipsEditSplit = "tabdo",
    UltiSnipsSnippetDirectories = { "UltiSnips", "snips" },
  },
}

V.require("user.plugins.ultisnips")

for k, v in pairs(user.plugins["ultisnips"].config) do
  vim.g[k] = v
end
