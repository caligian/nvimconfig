user.plugins["ultisnips"] = {
  UltiSnipsExpandSnippet = "<tab>",
  UltiSnipsJumpForwardTrigger = "<C-j>",
  UltiSnipsJumpBackwardTrigger = "<C-k>",
  UltiSnipsEditSplit = "tabdo",
  UltiSnipsSnippetDirectories = { "UltiSnips", "snips" },
}

V.require("user.plugins.ultisnips")

for k, v in pairs(user.plugins["ultisnips"]) do
  vim.g[k] = v
end
