local opts = { noremap = true }
Keybinding.bind(opts, {
	"<leader>li",
	partial(vim.diagnostic.open_float, { scope = "l", focus = false }),
	{ desc = "LSP diagnostic float", name = "lsp_diagnostic_float" },
}, {
	"[d",
	vim.diagnostic.goto_prev,
	{ desc = "LSP go to previous diagnostic", name = "lsp_prev_diagnostic" },
}, {
	"]d",
	vim.diagnostic.goto_next,
	{ desc = "LSP go to next diagnostic", name = "lsp_next_diagnostic" },
}, {
	"<leader>lq",
	vim.diagnostic.setloclist,
	{ desc = "LSP set loclist", name = "lsp_set_loclist" },
})
