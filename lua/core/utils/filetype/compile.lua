filetype.compile = module("filetype.compile")
local compile = filetype.compile

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

local function find_buffer_workspace(bufnr, pats, maxdepth, _depth)
	bufnr = bufnr or buffer.bufnr()
	if isstring(bufnr) then
		bufnr = buffer.bufnr(bufnr)
	end

	if not buffer.exists(bufnr) then
		return false
	end

	local lspconfig = require("lspconfig")
	local server = filetype.get(buffer.option(bufnr, "filetype"), "lsp_server")

	assert_type(server, union("string", "table"))

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

function filetype.workspace(p, pats, maxdepth, _depth)
	p = p or buffer.bufnr()
	return find_buffer_workspace(p, pats, maxdepth, _depth)
end

function compile.workspace() end

function compile.opts() end
