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
lang.jobs = lang.jobs or {}

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
function lang:setup_lsp(specs)
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

function lang:command(bufnr, action)
	action = action or "compile"
	local validactions = { "compile", "build", "test", "repl", "formatter" }

	params({
		buffer = { "number", bufnr },
		action = {
			function(x)
				return list.contains(validactions, x)
			end,
			action,
		},
	})

	assert(buffer.exists(bufnr), "invalid buffer: " .. dump(bufnr))
	local bufname = buffer.name(bufnr)
	local compile = self[action]
	local spec = union("string", "table", "function")

	if not compile then
		return
	else
		assert(isa[spec](compile))
	end

	if not istable(compile) then
		compile = { buffer = spec }
	end

	params({
		compile = {
			{
				__extra = true,
				["1?"] = spec,
				["buffer?"] = spec,
				["workspace?"] = spec,
				["dir?"] = spec,
			},
			compile,
		},
	})

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

	local out = dict.filter(compile, function(k, v)
		return (k ~= "buffer" and k ~= "workspace" and k ~= "dir" and k ~= 1) and v
	end)

	if compile[1] or compile.buffer then
		local cmd = dwim(compile[1] or compile.buffer, bufname)
		if cmd then
			out.buffer = { cmd, bufname }
		end
	end

	if compile.dir then
		local d = path.dirname(bufname)
		local cmd = dwim(compile.dir, d)
		if cmd then
			out.dir = { cmd, d }
		end
	end

	if compile.workspace then
		local ws = lang.workspace(bufnr)
		if ws then
			local cmd = dwim(compile.workspace, ws)
			if cmd then
				out.workspace = { cmd, ws }
			end
		end
	end

	if size(out) == 0 then
		error(self.name .. "." .. action .. ": no commands exist")
	end

	return out
end

function lang:format(bufnr, opts)
	opts = opts or {}
	local config = self:command(bufnr, "formatter")
	opts = copy(opts)
	local stdin = opts.stdin or config.stdin
	local write = opts.write or config.write
	local append_filename = opts.append_filename or config.append_filename
	local bufname = buffer.name(bufnr)
  local name
  
  if opts.dir then
    name = self.name .. '.formatter.dir.'
  elseif opts.workspace then
    name = self.name .. '.formatter.workspace.' 
  else
    name = self.name .. '.formatter.buffer.'
  end

  name = name .. bufname

	local function createcmd(tp)
		assert(config[tp], self.name .. ".formatter." .. tp .. ": no command exists")

		local cmd, target = unpack(config[tp])
		cmd = isa.list(args) and (cmd .. " " .. join(args, " ")) or cmd

		if tp == "buffer" then
      if append_filename == nil and stdin == nil then
        stdin = true
      end

			if append_filename then
				cmd = cmd .. " " .. target
			elseif stdin then
				cmd = sprintf('sh -c "cat %s | %s"', target, cmd)
      elseif cmd:match '%%path' then
        cmd = cmd:gsub('%%path', target)
      else
        cmd = cmd .. " " .. target
			end
		else
			if cmd:match("%%path") then
				cmd = cmd:gsub("%%path", target)
			else
				cmd = cmd .. " " .. target
			end
		end

		return cmd, target
	end

	local cmd, target
	if opts.workspace then
		cmd = createcmd("workspace")
	elseif opts.dir then
		cmd = createcmd("dir")
	else
		cmd = createcmd("buffer")
	end

	local winnr = buffer.winnr(bufnr)
	local view = winnr and win.save_view(winnr)
	opts.args = {}

	local proc = lang.job(cmd, {
    name = name,
		cwd = (opts.workspace or opts.dir) and target or path.dirname(bufname),
		before = function()
			vim.cmd(":w! " .. bufname)
			buffer.set_option(bufnr, "modifiable", false)
		end,
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

			local err = x.errors
			if #err > 0 then
				tostderr(join(err, "\n"))
				return
			end

			local out = x.lines
			if not out or #out == 0 then
				return
			else
				buffer.set_lines(bufnr, 0, -1, out)
			end

			if view then
				win.restore_view(winnr, view)
			end
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

function lang.job(cmd, opts)
	local name = opts.name

	if name then
		local j = lang.jobs[name]
		if j and job.isactive(j) then
      job.close(j)
		end
	end

	opts.stdout = true
	opts.args = opts.args or {}
	opts.stderr = true
	opts.output = true

	--- @diagnostic disable-next-line: param-type-mismatch
	local ok, msg = pcall(job, cmd, opts)

	if not ok then
		tostderr(msg)
		return
	else
		j = msg
	end

	if name then
		lang.jobs[name] = j
	end

	return j
end

function lang:action(action, cmd, opts) end

lang({
	name = "lua",
	formatter = {
		buffer = "stylua -",
		dir = "stylua",
		stdin = true,
		write = true,
	},
})
