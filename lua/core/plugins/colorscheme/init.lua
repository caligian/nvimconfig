Autocmd("Colorscheme", {
  name = "change_linenr_bg",
  pattern = "*",
  callback = function()
    local normal = utils.highlight "Normal"
    utils.highlightset("LineNr", { guibg = normal.guibg })
  end,
})

user.colorscheme = user.colorscheme or function ()
  require("kanagawa").setup {
    compile = false,
    undercurl = true,
    commentStyle = { italic = true },
    functionStyle = {},
    keywordStyle = { italic = true },
    statementStyle = { bold = true },
    typeStyle = {},
    transparent = false,
    dimInactive = false,
    terminalColors = true,
    colors = {
      palette = {},
      theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
    },
    overrides = function(...) return {} end,
    theme = "dragon",
    background = { dark = "dragon", light = "lotus" },
  }

  vim.cmd('color kanagawa')
end

user.colorscheme()
