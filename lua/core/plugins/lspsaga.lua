local lspsaga = plugin.get("lspsaga")

lspsaga.config = {
	ui = {
		code_action = "?",
	},
}

lspsaga.mappings = {
	opts = { leader = true, prefix = "l", silent = true, noremap = true },

	finder = {
		"f",
		":Lspsaga finder ref<CR>",
		"show refs+defs+impl",
	},

	outgoing = {
		"I",
		":Lspsaga outgoing_calls<CR>",
		"outgoing calls",
	},

	incoming = {
		"i",
		":Lspsaga incoming_calls<CR>",
		"incoming calls",
	},

	actions = {
		"a",
		":Lspsaga code_action<CR>",
		"show code actions",
	},

	peek = {
		"p",
		":Lspsaga peek_definition<CR>",
		"peek def",
	},

	peek_type = {
		"P",
		":Lspsaga peek_type_definition<CR>",
		"peek typedef",
	},

	rename = {
		"/",
		"<cmd>Lspsaga rename<CR>",
		"rename",
	},

	project_replace = {
		"%",
		":Lspsaga project_replace",
		"project replace",
	},

	outline = {
		"o",
		"<cmd>Lspsaga outline<CR>",
		"outline",
	},

	buf_diags = {
		"d",
		"<cmd>Lspsaga show_buf_diagnostics ++float<CR>",
		"diagnostics",
	},

	diags = {
		"D",
		"<cmd>Lspsaga show_workspace_diagnostics ++float<CR>",
		"ws diagnostics",
	},
}

function lspsaga:setup()
	require("lspsaga").setup(lspsaga.config)

	kbd.map_group("lspsaga", {
		line_diag = { "n", "<A-k>", "<cmd>Lspsaga show_line_diagnostics<CR>", { desc = "line diagnostics" } },
		doc = { "n", "K", "<cmd>Lspsaga hover_doc<CR>", { desc = "hover doc" } },
		next_diag = { "n", "]e", "<cmd>Lspsaga diagnostic_jump_next<CR>", { desc = "next diag" } },
		prev_diag = { "n", "[e", "<cmd>Lspsaga diagnostic_jump_prev<CR>", { desc = "prev diag" } },
	})
end

return lspsaga
