-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
Keybinding.bind(
	{ noremap = true },
	{
		"<leader>li",
		V.partial(vim.diagnostic.open_float, { scope = "l", focus = false }),
		"LSP diagnostic float",
	},
	{ "[d", vim.diagnostic.goto_prev, "LSP go to previous diagnostic" },
	{ "]d", vim.diagnostic.goto_next, "LSP go to next diagnostic" },
	{ "<leader>lq", vim.diagnostic.setloclist, "LSP set loclist" }
)
