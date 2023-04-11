require("utils.Keybinding")

local fennel = require("fennel")
Fennel = {}
fennel.install()
debug.traceback = fennel.traceback
Fennel.eval = fennel.eval
Fennel.parse_string = fennel.compileString
Fennel.eval_file = fennel.dofile
Fennel.dofile = fennel.dofile

function Fennel.parse_buffer(bufnr)
	bufnr = bufnr or vim.fn.bufnr()
	return Fennel.parse_string(table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n"), {
		filename = vim.api.nvim_buf_get_name(bufnr),
		indent = 2,
	})
end

function Fennel.parse_file(p)
	assert(path.exists(p), "invalid path given " .. p)
	return Fennel.parse_string(file.read(p), { filename = p })
end

function Fennel.eval_file(p)
	return Fennel.eval(Fennel.parse_file(p), { filename = p })
end

function Fennel.eval_buffer(bufnr)
	bufnr = bufnr or vim.fn.bufnr()
	return Fennel.eval(Fennel.parse_buffer(bufnr), {
		filename = vim.api.nvim_buf_get_name(bufnr),
	})
end

function Fennel.compile_buffer(bufnr)
	bufnr = bufnr or vim.fn.bufnr()
	local bufname = vim.api.nvim_buf_get_name(bufnr)
	if not bufname:match("%.fnl$") then
		return
	end
	bufname = bufname:gsub("%.fnl$", "%.lua")
	local s = Fennel.parse_buffer(bufnr)
	file.write(bufname, s)

	return s
end

function Fennel.compile_file(p)
	local dest = p:gsub("%.fnl$", "%.lua")
	local s = Fennel.parse_file(p)
	file.write(dest, s)

	return s
end

K.bind({
	event = "BufEnter",
	pattern = "*.fnl",
	noremap = true,
	prefix = ",c",
}, {
	"c",
	function()
		print("Compiling buffer to lua: " .. vim.fn.bufname())
		Fennel.compile_buffer()
	end,
	"To Lua in cwd",
})
