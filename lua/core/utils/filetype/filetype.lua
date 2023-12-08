require("core.utils.au")
require("core.utils.buffer")
require("core.utils.win")
require("core.utils.kbd")
require("core.utils.job")

--- @class lang
--- @field langs { [string]: lang }
--- @overload fun(string): lang
lang = lang or class("lang")
-- lang.langs = lang.langs or {}
lang.langs = {}

--- @class lang.lsp
lang.lsp = module("lang.lsp")

lang.lsp.diagnostic = { virtual_text = false, underline = false, update_in_insert = false }

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
	border = "single",
	title = "hover",
})

vim.diagnostic.config(lang.lsp.diagnostic)

lang.lsp.mappings = lang.lsp.mappings
	or {
		diagnostic = {
			opts = { noremap = true, leader = true },
			float_diagnostic = {
				"<leader>li",
				partial(vim.diagnostic.open_float, { scope = "l", focus = false }),
				{ desc = "LSP diagnostic float" },
			},
			previous_diagnostic = {
				"[d",
				vim.diagnostic.gotoprev,
				{ desc = "LSP go to previous diagnostic" },
			},
			next_diagnostic = {
				"]d",
				vim.diagnostic.gotonext,
				{ desc = "LSP go to next diagnostic" },
			},
			set_loclist = {
				"lq",
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
				"<leader>la",
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

function lang.lsp.fix_omnisharp(client, _)
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

function lang.lsp.attach_formatter(client)
	require("lsp-format").on_attach(client)
end

function lang.lsp.on_attach(client, bufnr)
	if client.name == "omnisharp" then
		lsp.fix_omnisharp(client)
	else
		buffer.set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

		local ft = vim.bo.filetype
		local has_formatter = lang(ft)
		if has_formatter and not has_formatter.formatter then
			lang.lsp.attach_formatter(client)
		end

		local mappings = deepcopy(lang.lsp.mappings)
		for _, value in pairs(mappings) do
			value.buffer = bufnr
		end

		kbd.map_groups(mappings)
	end
end

function lang.lsp.setup_server(server, opts)
	opts = opts or {}
	local capabilities = opts.capabilities or require("cmp_nvim_lsp").default_capabilities()
	local on_attach = opts.on_attach or lsp.on_attach
	local flags = opts.flags or lsp.flags
	local default_conf = { capabilities = capabilities, on_attach = on_attach, flags = flags }

	default_conf = dict.merge(default_conf, opts)

	if default_conf.cmd then
		default_conf.cmd = tolist(default_conf.cmd)
	end

	require("lspconfig")[server].setup(default_conf)
end

function lang:islang()
	return typeof(x) == "lang"
end

function lang:init(name)
	if lang.islang(name) then
		return name
	elseif istable(name) then
		assert(name.name, "name is missing in " .. dump(name))
		local l = lang(name.name)
		dict.merge(l, name)

		lang.langs[name.name] = l
		return l
	elseif isnumber(name) then
		assert(buffer.exists(name), "invalid buffer " .. name)
		return lang(buffer.filetype(name))
	else
		local l = lang.langs[name]
		if l then
			return l
		end
	end

	self.name = name

	--- @see vim.filetype
	self.match = false
	self.autocmds = false
	self.kbds = false
	self.formatter = false
	self.config_path = false
	self.user_config_path = false
	self.compile = false
	self.build = false
	self.compile = false
	self.test = false
	self.bo = false
	self.wo = false
	self.jobs = {}

	return self
end

function lang:fromdict(specs)
	local name = specs.name
	local x = lang(name)
	dict.merge(x, specs)

	return x
end

function lang:autocmd(callback, opts)
	opts = opts or {}
	opts.pattern = self.name
	opts.callback = callback

	return autocmd.map("Filetype", opts)
end

function lang:setbo(bo)
	bo = bo or self.bo
	asserttype(bo, "table")

	self:autocmd(function(opts)
		buffer.set_option(opts.buf, bo)
	end)
end

function lang:setwo(wo)
	wo = wo or self.wo
	asserttype(wo, "table")

	self:autocmd(function(opts)
		win.set_option(opts.buf, wo)
	end)
end

--- @param specs { [1]: string, config: table }
function lang:setuplsp(specs)
	specs = specs or self.lsp
	specs = isstring(specs) and { specs } --[[@as table]]

	if not specs then
		return
	end

	lang.lsp.setup_server(specs[1], specs.config)

	return self
end

function lang:getjob(name, noprefix)
	if not name then
		return
	end

	name = not noprefix and ("filetype." .. self.name .. "." .. name) or name
	return self.jobs[name]
end

local function find_workspace(start_dir, pats, maxdepth, _depth)
	maxdepth = maxdepth or 5
	_depth = _depth or 0
	pats = tolist(pats or "%.git$")

	if maxdepth == _depth then
		return false
	end

	if not path.isdir(start_dir) then
		return false
	end

	local parent = path.dirname(start_dir)
	local children = dir.getfiles(start_dir)

	for i = 1, #pats do
		local pat = pats[i]

		for j = 1, #children do
			if children[j]:match(pat) then
				return children[j]
			end
		end
	end

	return find_workspace(parent, pats, maxdepth, _depth + 1)
end

function lang:query(attrib, f)
	self = lang(self)

	if self[attrib] then
		return f and f(self[attrib]) or self[attrib]
	end
end

function lang.workspace(bufnr, pats, maxdepth, _depth)
	bufnr = bufnr or buffer.bufnr()
	if isstring(bufnr) then
		bufnr = buffer.bufnr(bufnr)
	end

	if not buffer.exists(bufnr) then
		return false
	end

	local lspconfig = require("lspconfig")
	---@diagnostic disable-next-line: param-type-mismatch
	local server = lang.query(buffer.filetype(bufnr), "server")

	asserttype(server, union("string", "table"))

	local bufname = buffer.name(bufnr)
	local config = isstring(server) and lspconfig[server] or lspconfig[server[1]]
	local root_dir_checker = config.document_config.default_config.root_dir

	if not server then
		return find_workspace(bufname, pats, maxdepth, _depth)
	end

	if not config.get_root_dir then
		return find_workspace(bufname, pats, maxdepth, _depth)
	elseif root_dir_checker then
		return root_dir_checker(bufname)
	end

	return config.get_root_dir(bufname)
end

local function getcmd(ft, x, p)
	assert(buffer.exists(p), "invalid buffer: " .. dump(p))
	p = buffer.name(p)

	local function getfromtable(X, what)
		for key, value in pairs(X) do
			if what:match(key) then
				return value
			end
		end
	end

	local function dwim(X, what)
		if isfunction(X) then
			return X(what)
		elseif isstring(X) then
			return X
		else
			return getfromtable(X, what)
		end
	end

	if istable(x) then
		if x.workspace then
			local ws = lang.workspace(bufnr)
			assert(ws, bufname .. ": not in workspace")
			return dwim(x.workspace, ws), ws
		elseif x.dir then
			local d = path.dirname(p)
			return dwim(x.dir, d), d
		else
			return dwim(x[1] or x.buffer, d), d
		end
	elseif isstring(x) then
		return x
	elseif isfunction(x) then
		return x(p)
	end

	error(ft .. ".formatter: no command found for " .. p)
end

function lang:format(bufnr, opts)
	local config = not istable(self.formatter) and { self.formatter } or self.formatter
	local strtablefn = union("string", "table", "function")

	assert(isa[strtablefn](config))

	params({
		cmd = {
			{
				[1] = strtablefn,
				["workspace?"] = strtablefn,
				["dir?"] = strtablefn,
			},
			config,
		},
	})

	opts = opts or {}
	opts = copy(opts)
	dict.merge(opts, config or {})

	local ws_or_d
	bufnr = bufnr or buffer.bufnr()
	cmd, ws_or_d = getcmd(self.name, opts, bufnr)
	local stdin = opts.stdin
	local write = opts.write
	local append_filename = opts.append_filename
	opts.stdin = nil
	opts.write = nil
	opts.append_filename = nil
	local bufname = buffer.name(bufnr)

	if opts.workspace then
		cmd = cmd .. " " .. ws_or_d

		local args = opts.args
		if isa.list(args) then
			cmd = cmd .. " " .. join(args, " ")
		end
	elseif opts.dir then
		cmd = cmd .. " " .. ws_or_d

		local args = opts.args
		if isa.list(args) then
			cmd = cmd .. " " .. join(args, " ")
		end
	else
		local args = opts.args
		if isa.list(args) then
			cmd = cmd .. " " .. join(args, " ")
		end

		if append_filename == nil and stdin == nil then
			stdin = true
		end

		if stdin then
			---@diagnostic disable-next-line
			cmd = sprintf('sh -c "cat %%path | %s"', cmd)
		elseif append_filename then
			cmd = cmd .. " " .. bufname
		end
	end

	opts.args = {}

	vim.cmd(":w! " .. bufname)
	buffer.set_option(bufnr, "modifiable", false)
	local winnr = buffer.winnr(bufnr)
	local view = winnr and win.save_view(winnr)
	local proc = self:job(bufnr, cmd, {
		output = true,
		on_exit = function(x)
			if x.exit_code ~= 0 then
				buffer.set_option(bufnr, "modifiable", true)

				local err = #x.errors > 1 and x.errors or #x.lines > 1 and x.lines
				if err then
					---@diagnostic disable-next-line: cast-local-type
					err = join(err, "\n")
					tostderr(err)
				else
					print("check source syntax for buffer " .. bufname)
				end

				return
			end

			buffer.set_option(bufnr, "modifiable", true)

			if write then
				buffer.call(bufnr, function()
					vim.cmd(":e! " .. bufname)

					if view then
						win.restore_view(winnr, view)
					end
				end)

				return
			end

			local err = x.errors
			if #err > 0 then
				tostderr(join(err, "\n"))
				return
			end

			local out = x.lines
			if not out then
				return
			elseif #out > 0 then
				buffer.set_lines(bufnr, 0, -1, out)
			end

			if view then
				win.restore_view(winnr, view)
			end

			vim.cmd(":e!")
		end,
	})

	return proc
end

function lang:format_dir(bufnr, opts)
	opts = opts or {}
	opts.dir = true
	return self:format(bufnr, opts)
end

function lang:format_workspace(bufnr, opts)
	opts = opts or {}
	opts.workspace = true
	return self:format(bufnr, opts)
end

function lang:job(bufnr, cmd, opts)
	opts = copy(opts or {})
	local name = opts.name
	local ws = opts.workspace
	local fordir = opts.dir
	local template = opts.template
		or function(x, args, usepath)
			if x:match("%%path") then
				x = x:gsub("%%path", usepath)
				return x, args
			end

			for i = 1, #args do
				if args[i]:match("%%path") then
					args[i] = args[i]:gsub("%%path", usepath)
					return x, args
				end
			end

			return x, args
		end

	opts.name = nil
	opts.workspace = nil
	opts.dir = nil
	opts.template = nil

	if name then
		name = "filetype." .. self.name .. "." .. name
	end

	local j = self:getjob(name)
	if j and job.isactive(j) then
		return j
	end

	bufnr = bufnr or buffer.current()
	assert(buffer.exists(bufnr), "invalid buffer: " .. bufnr)

	local usepath
	local bufname = buffer.name(bufnr)

	if ws then
		usepath = lang.workspace(bufnr)
		assert(usepath, bufname .. ": not in workspace")
	elseif fordir then
		usepath = path.dirname(bufname)
	else
		usepath = bufname
	end

	assert(cmd, bufname .. ": no command provided")

	opts.stdout = true
	opts.args = opts.args or {}
	opts.cwd = ws and usepath or fordir and usepath or path.dirname(bufname)
	opts.stderr = true

	local _cmd, _args = template(cmd, opts.args, usepath)
	cmd = _cmd
	opts.args = _args

	---@diagnostic disable-next-line: param-type-mismatch
	local ok, msg = pcall(job, cmd, opts)

	if not ok then
		tostderr(msg)
		buffer.set_option(bufnr, "modifiable", true)
		return
	else
		j = msg
	end

	if name then
		self.jobs[name] = j
	end

	return j
end

lang({
	name = "lua",
	formatter = {
		"stylua -",
		dir = "stylua",
	},
})

j = lang.langs.lua:format_dir()
