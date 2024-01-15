return {
  highlight_on_yank = {
    "TextYankPost",
    {
      pattern = "*",
      callback = function()
        vim.highlight.on_yank { timeout = 200 }
      end,
    },
  },

  textwidth_colorcolumn = {
    "BufAdd",
    {
      pattern = "*",
      callback = function()
        Win.set_option(vim.fn.bufnr(), "colorcolumn", "+2")
      end,
    },
  },
}
