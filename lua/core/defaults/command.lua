local command = utils.command

-- Open logs
command("ShowLogs", function()
	local log_path = vim.fn.stdpath("config") .. "/nvim.log"
	if path.exists(log_path) then
		vim.cmd("tabnew " .. log_path)
		vim.cmd("setlocal readonly")
		vim.cmd("noremap <buffer> q :bwipeout <bar> b#<CR>")
	end
end, {})

-- Open scratch buffer
command("OpenScratch", function()
	Buffer.open_scratch()
end, {})

command("OpenScratchVertically", function()
	Buffer.open_scratch(false, "v")
end, {})

-- Compile neovim lua
local function compile_and_run(lines)
	if is_a(lines, "table") then
		lines = table.concat(lines, "\n")
	end

	local compiled, err = loadstring(lines)
	if err then
		utils.nvimerr(err)
	elseif compiled then
		compiled()
	end
end

-- Setup commands
command("NvimEvalRegion", function()
	local lines = utils.visualrange()
	compile_and_run(lines)
end, { range = true })

command("NvimEvalBuffer", function()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	compile_and_run(lines)
end, {})

command("NvimEvalTillPoint", function()
	local line = vim.fn.line(".")
	local lines = vim.api.nvim_buf_get_lines(0, 0, line - 1, false)
	compile_and_run(lines)
end, {})

command("NvimEvalLine", function()
	local line = vim.fn.getline(".")
	compile_and_run(line)
end, {})

-- Only works for guifg and guibg
command("Darken", function(args)
	args = vim.split(args.args, " +")
	assert(#args == 2)

	local what, by = unpack(args)
	local hi = utils.highlight("Normal")

	if isblank(hi) then
		return
	end

	local set = {}
	if what == "fg" then
		set["guifg"] = utils.darken(hi["guifg"], tonumber(by))
	else
		set["guibg"] = utils.darken(hi["guibg"], tonumber(by))
	end

	utils.highlightset("Normal", set)
end, { nargs = "+" })

-- Only works with guifont
-- :FontSize points
command("FontSize", function(args)
	args = vim.split(args.args, " +")
	args = args[1]
	local font, height = utils.get_font()
	local inc = args:match("^([-+])")
	args = args:gsub("^[-+]", "")
	args = tonumber(args)

	if inc == "+" then
		height = height + args
	elseif inc == "-" then
		height = height - args
	else
		height = args
	end
	height = args == "" and 12 or height

	utils.set_font(font, height)
end, { nargs = "+" })

command("TrimWhiteSpace", function()
	local layout = vim.fn.winsaveview()
	vim.cmd("keeppatterns %s/\\s\\+$//e")
	vim.fn.winrestview(layout)
end, {})
