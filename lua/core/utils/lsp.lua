lsp = {}
lsp.diagnostic = { virtual_text = false, underline = false, update_in_insert = false }

vim.diagnostic.config(lsp.diagnostic)

lsp.mappings = {
	diagnostic = {
		opts = { noremap = true, leader = true },
		float_diagnostic = {
			"<leader>li",
			partial(vim.diagnostic.open_float, { scope = "l", focus = false }),
			{ desc = "LSP diagnostic float" },
		},
		previous_diagnostic = {
			"[d",
			vim.diagnostic.goto_prev,
			{ desc = "LSP go to previous diagnostic" },
		},
		next_diagnostic = {
			"]d",
			vim.diagnostic.goto_next,
			{ desc = "LSP go to next diagnostic" },
		},
		set_loclist = {
			"<leader>lq",
			vim.diagnostic.setloclist,
			{ desc = "LSP set loclist" },
		},
	},
	lsp = {
		opts = { silent = true, noremap = true },
		buffer_declarations = {
			"gD",
			vim.lsp.buf.declaration,
			{ desc = "Buffer declarations" },
		},
		buffer_definitions = {
			"gd",
			vim.lsp.buf.definition,
			{ desc = "Buffer definitions" },
		},
		float_documentation = {
			"K",
			vim.lsp.buf.hover,
			{ desc = "Show float UI" },
		},
		implementations = {
			"gi",
			vim.lsp.buf.implementation,
			{ desc = "Show implementations" },
		},
		signatures = {
			"<C-k>",
			vim.lsp.buf.signature_help,
			{ desc = "Signatures" },
		},
		add_workspace_folder = {
			"<leader>lwa",
			vim.lsp.buf.add_workspace_folder,
			{ desc = "Add workspace folder" },
		},
		remove_workspace_folder = {
			"<leader>lwr",
			vim.lsp.buf.remove_workspace_folder,
			{ desc = "Remove workspace folder" },
		},
		list_workspace_folders = {
			"<leader>lwl",
			function()
				print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
			end,
			{ desc = "List workspace folders" },
		},
		type_definition = {
			"<leader>lD",
			vim.lsp.buf.type_definition,
			{ desc = "Show type definitions" },
		},
		buffer_rename = {
			"<leader>lR",
			vim.lsp.buf.rename,
			{ desc = "Rename buffer" },
		},
		code_action = {
			"leaderla",
			vim.lsp.buf.code_action,
			{ desc = "Show code actions" },
		},
		buffer_references = {
			"gr",
			vim.lsp.buf.references,
			{ desc = "Show buffer references" },
		},
	},
}

function lsp.fix_omnisharp(client, bufnr)
	client.server_capabilities.semanticTokensProvider = {
		full = vim.empty_dict(),
		legend = {
			tokenModifiers = { "static_symbol" },
			tokenTypes = {
				"comment",
				"excluded_code",
				"identifier",
				"keyword",
				"keyword_control",
				"number",
				"operator",
				"operator_overloaded",
				"preprocessor_keyword",
				"string",
				"whitespace",
				"text",
				"static_symbol",
				"preprocessor_text",
				"punctuation",
				"string_verbatim",
				"string_escape_character",
				"class_name",
				"delegate_name",
				"enum_name",
				"interface_name",
				"module_name",
				"struct_name",
				"type_parameter_name",
				"field_name",
				"enum_member_name",
				"constant_name",
				"local_name",
				"parameter_name",
				"method_name",
				"extension_method_name",
				"property_name",
				"event_name",
				"namespace_name",
				"label_name",
				"xml_doc_comment_attribute_name",
				"xml_doc_comment_attribute_quotes",
				"xml_doc_comment_attribute_value",
				"xml_doc_comment_cdata_section",
				"xml_doc_comment_comment",
				"xml_doc_comment_delimiter",
				"xml_doc_comment_entity_reference",
				"xml_doc_comment_name",
				"xml_doc_comment_processing_instruction",
				"xml_doc_comment_text",
				"xml_literal_attribute_name",
				"xml_literal_attribute_quotes",
				"xml_literal_attribute_value",
				"xml_literal_cdata_section",
				"xml_literal_comment",
				"xml_literal_delimiter",
				"xml_literal_embedded_expression",
				"xml_literal_entity_reference",
				"xml_literal_name",
				"xml_literal_processing_instruction",
				"xml_literal_text",
				"regex_comment",
				"regex_character_class",
				"regex_anchor",
				"regex_quantifier",
				"regex_grouping",
				"regex_alternation",
				"regex_text",
				"regex_self_escaped_character",
				"regex_other_escape",
			},
		},
		range = true,
	}
end

function lsp.apply_mappings(overrides, callback)
	local mappings = deepcopy(lsp.mappings)
	if overrides then
		dict.merge(mappings, overrides)
	end
	kbd.map_with_groups(mappings, callback)
end

function lsp.attach_formatter(client)
	require("lsp-format").on_attach(client)
end

function lsp.on_attach(client, bufnr)
	if client.name == "omnisharp" then
		lsp.fix_omnisharp(client)
	else
		buffer.setoption(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

		local ft = vim.bo.filetype
		local has_formatter = filetype[ft].formatter
		if not has_formatter then
			lsp.attach_formatter(client)
		end

		lsp.apply_mappings({}, function(mode, ks, cb, rest)
			rest.buffer = bufnr
			return mode, ks, cb, rest
		end)
	end
end

function lsp.setup_server(server, opts)
	opts = opts or {}
	local capabilities = opts.capabilities or require("cmp_nvim_lsp").default_capabilities()
	local on_attach = opts.on_attach or lsp.on_attach
	local flags = opts.flags or lsp.flags
	local default_conf = { capabilities = capabilities, on_attach = on_attach, flags = flags }

	default_conf = dict.merge(default_conf, opts)

	if default_conf.cmd then
		default_conf.cmd = array.to_array(default_conf.cmd)
	end

	require("lspconfig")[server].setup(default_conf)
end
