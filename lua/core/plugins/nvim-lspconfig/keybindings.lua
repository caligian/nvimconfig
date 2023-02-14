local opts = { noremap = true }
user.plugins["nvim-lspconfig"].kbd = {
  lsp_diagnostic_in_float = Keybinding.bind(opts, {
    "<leader>li",
    V.partial(vim.diagnostic.open_float, { scope = "l", focus = false }),
    "LSP diagnostic float",
  }),
  lsp_goto_prev_diagnostic = Keybinding.bind(
    opts,
    { "[d", vim.diagnostic.goto_prev, "LSP go to previous diagnostic" }
  ),
  lsp_goto_next_diagnostic = Keybinding.bind(
    opts,
    { "]d", vim.diagnostic.goto_next, "LSP go to next diagnostic" }
  ),
  lsp_set_loclist = Keybinding.bind(
    opts,
    { "<leader>lq", vim.diagnostic.setloclist, "LSP set loclist" }
  ),
}
