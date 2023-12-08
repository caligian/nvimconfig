require("core.utils.buffer")

ft = ft or module("ft")
-- ft.fts = ft.fts or {}
ft.fts = {}
local utils = {}

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

function utils.workspace(bufnr, pats, maxdepth, _depth)
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

function utils.isft(ft)
	if not ft then
		return false
	end

	return mtget(ft, "type") == ("ft." .. ft)
end

utils.isfiletype = utils.isft

function utils.load(FT)
	if not FT then
		local vimdir = os.getenv("HOME") .. "/.config/nvim/lua/core/ft"
		local userdir = os.getenv("HOME") .. "/.nvim/lua/user/ft"
		local fts1 = vim.fn.glob(vimdir .. "/*.lua")
		local fts2 = vim.fn.glob(userdir .. "/*.lua")
		fts1 = set(#fts1 == 0 and {} or chomp(split(fts1, "\n")))
		fts2 = set(#fts2 == 0 and {} or chomp(split(fts2, "\n")))

		if set.length(fts1) == 0 and set.length(fts2) == 0 then
			return false
		end

		local fts = set.union(fts1, fts2)
		fts = set.map(fts, function(x)
			return path.basename(x):gsub("%.lua$", "")
		end)
		ft = fts
	end

	if isstring(FT) then
		--- add logging
		local config, user_config, _
		_, config = pcall(require, "core.ft." .. FT)
		_, user_config = pcall(require, "user.ft." .. FT)

		if not istable(config) and not istable(user_config) then
			return false
		end

		dict.merge(config, not istable(user_config) and {} or user_config)
		mtset(config, "type", "ft." .. FT)

		ft.fts[FT] = config

		return config
	elseif istable(FT) then
		local _configs = {}
		for i = 1, #FT do
			_configs[FT[i]] = utils.load(FT[i])
		end

		return _configs
	end
end

--- Get attributes for filetype
--- @overload fun(config: table, attrib: string, f?: function): string|table
--- @overload fun(ft: string, attrib: string, f?: function): string|table
--- @overload fun(bufnr: number, attrib: string, f?: function): string|table
utils.attrib = defmulti({
	[{ "table", "string" }] = function(config, attrib, f)
		local value = config[attrib]
		return value and (f and f(value) or value)
	end,

	[{ "string", "string" }] = function(config, attrib, f)
		config = ft.fts[config]
		local value = config and config[attrib]
		return value and (f and f(value) or value)
	end,

	[{ "number", "string" }] = function(config, attrib, f)
		local value = buffer.filetype(config)
		value = ft.fts[value]
		return value and (f and f(value) or value)
	end,
})

--- Get config for filetype
--- @overload fun(bufnr: number, f: function): string|table
--- @overload fun(ft: string, f: function): string|table
utils.config = defmulti({
	[{ "number" }] = function(FT, f)
		local value = ft.fts[buffer.filetype(FT)]
		return value and (f and f(value) or value)
	end,

	[{ "string" }] = function(FT, f)
		local value = ft.fts[FT]
		return value and (f and f(value) or value)
	end,
})

--- return command string
--- @param FT string filetype
--- @param action? "compile"|"build"|"test"|"formatter"
--- @return { buffer?: string, workspace?: string, dir?: string, stdin?: boolean }
function utils.command(FT, action, bufnr)
	--[[
  spec:
  ---
  command spec for compile, build, test:
  string | fun(bufname): string | table<string|fun(bufname, workspace?): string>

  compile, build, test = string | fun(bufname, workspace?): string | {
    buffer? = <command>,
    workspace? = <command>,
    dir? = <command>,
  }

  formatter = string | fun(bufname, workspace?): string | {
    buffer? = <command>,
    workspace? = <command>,
    dir? = string | fun(dirname): string | table<string|fun(dirname): string>,
    stdin? = boolean,
  }
  --]]
	--
	action = action or "compile"
	local config = utils.config(FT)

	if not config then
		return false
	end

	local ftname = config.filetype
	config = config[action]

	if not config then
		return
	end

	if isstring(config) then
		return { buffer = config }
	end

	local buf = config.buffer or config[1]
	local ws = config.workspace
	local d = config.dir

	assert(buf or ws or d, "no buffer/workspace/dir command provided for " .. ftname)

	bufnr = bufnr or buffer.current()
	local bufname = buffer.name(bufnr)
	local dirname = path.dirname(bufname)
	local ws = utils.workspace(bufname)

	return { buffer = buf, workspace = ws, dir = d }
end

utils.load("lua")
pp(utils.command("lua"))
