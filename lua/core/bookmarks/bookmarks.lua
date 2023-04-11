if not Bookmarks then
	Bookmarks = {}
end
local B = Bookmarks
Bookmarks.dest = vim.fn.stdpath("data") .. "/bookmarks.lua"
Bookmarks.bookmarks = Bookmarks.bookmarks or {}
Bookmarks._cache = Bookmarks._cache or {}
-- Bookmarks._cache = {}
local _cache = Bookmarks._cache

function B.get_path(p)
	validate.path(is({ "s", "n" }), p)

	if p == 0 then
		p = vim.fn.bufnr()
	end
	local is_buffer = vim.fn.bufexists(p) ~= 0
	local is_file = is_a.string(p) and path.exists(p)
	if not is_buffer and not is_file then
		return
	end

	if B.bookmarks[p] then
		return B.bookmarks[p]
	elseif _cache[p] then
		return _cache[p]
	end

	if is_buffer then
		local bufnr = vim.fn.bufnr()
		local bufname = vim.api.nvim_buf_get_name(bufnr)
		if #bufname == 0 then
			return
		end

		if path.isdir(bufname) then
			_cache[p] = {
				dir = true,
				path = bufname,
			}
		else
			local loaded = vim.fn.bufloaded(bufnr) == 1
			if not loaded then
				return
			end
			local listed = vim.api.nvim_buf_get_option(bufnr, "buflisted")
			if not listed then
				return
			end
			_cache[p] = {
				bufnr = bufnr,
				path = bufname,
				dir = false,
				file = true,
				lines = {},
			}
		end
	elseif path.isdir(p) then
		_cache[p] = {
			dir = true,
			file = false,
			path = path.abspath(p),
		}
	else
		_cache[p] = {
			dir = false,
			file = true,
			path = p,
			lines = {},
		}
	end

	return _cache[p]
end

function B.exists(p, line)
	p = B.get_path(p)
	if not p then
		return false
	end
	local obj = B.bookmarks[p.path]

	if not line then
		return obj
	else
		return obj.lines[line]
	end
end

function B.clean()
	local function _clean(bufnr, state)
		if not state.lines then
			return
		end
		for line, obj in pairs(state.lines) do
			local n
			if is_a.number(bufnr) then
				n = vim.api.nvim_buf_line_count(bufnr)
			else
				n = #(vim.split(file.read(bufnr), "\n"))
			end
			if line > n or line < 1 then
				state.lines[line] = nil
			end
		end
	end

	for k, v in pairs(B.bookmarks) do
		if is_a.number(k) then
			local bufnr = k
			if vim.fn.bufexists(bufnr) ~= 0 then
				_clean(bufnr, v)
			elseif not path.exists(v.path) then
				B.bookmarks[v.path] = nil
				_cache[v.path] = nil
			end
		else
			if not path.exists(k) then
				B.bookmarks[k] = nil
				_cache[k] = nil
			else
				_clean(k, v)
			end
		end
	end
end

function B.path2bufnr(p)
	if vim.fn.bufexists(p) == 0 then
		return p
	end
	return vim.fn.bufnr(p)
end

function B.get_pos(bufnr)
	if vim.fn.bufwinid(bufnr) == -1 then
		return
	end

	return vim.api.nvim_buf_call(bufnr, function()
		local pos = vim.fn.getpos(".")
		return pos[2], pos[3]
	end)
end

local function get_context(p, line)
	line = line or "."
	if not p or p.dir then
		return
	elseif not p.bufnr then
		return vim.split(file.read(p.path), "\n")[line]
	elseif line == "." then
		local row, _ = B.get_pos(p.bufnr)
		return vim.api.nvim_buf_get_lines(p.bufnr, row - 1, row, false)[1], row
	end
	return vim.api.nvim_buf_get_lines(p.bufnr, line - 1, line, false)[1], line
end

function B.update(p, line)
	validate["?line"](function(x)
		local msg = "'.' for current line or line number"
		local ok = x == "." or is_a.number(x)
		if not ok then
			return ok, msg
		end
		return true
	end, line)

	line = line or "."
	p = B.get_path(p)
	if not p then
		return
	end

	if p.bufnr then
		B.bookmarks[p.bufnr] = p
	end
	B.bookmarks[p.path] = p
	if p.dir then
		return
	end

	local context
	p.lines = p.lines or {}
	context, line = get_context(p, line)
	if #context ~= 0 then
		p.lines[line] = context
	end

	return p
end

function B.save()
	B.clean()

	file.write(B.dest, sprintf("return %s", dump(B.list())))
end

function B.load()
	local ok = loadfile(B.dest)
	if ok then
		B.bookmarks = ok()
	else
		B.bookmarks = {}
	end
end

function B.remove(p, line)
	if not line then
		p = B.exists(p)
		B.bookmarks[p.path] = nil
		B.bookmarks[p.bufnr] = nil
	end

	p = B.exists(p)
	if not p then
		return
	end
	B.bookmarks[p.path].lines[line] = nil
	if B.bookmarks[p.bufnr] then
		B.bookmarks[p.bufnr][line] = nil
	end
end

function B.add(p, line)
	p = p or vim.fn.bufnr()
	B.update(p, line)
end

function B.list(p, telescope)
	B.clean()

	if dict.isblank(B.bookmarks) then
		return
	end

	if not p then
		if telescope then
			return {
				results = array.grep(dict.keys(B.bookmarks), function(k)
					return not is_a.number(k)
				end),
				entry_maker = function(entry)
					return {
						ordinal = -1,
						value = entry,
						display = entry,
						path = entry,
					}
				end,
			}
		end

		return dict.grep(B.bookmarks, function(k, _)
			return not is_a.number(k)
		end)
	end

	p = B.exists(p)
	if not p then
		return
	elseif not p.lines then
		return
	elseif dict.isblank(p.lines) then
		return
	end

	if telescope then
		return {
			results = dict.items(p.lines),
			entry_maker = function(entry)
				return {
					ordinal = entry[1],
					line = entry[1],
					context = entry[2],
					display = sprintf("%d: %s", entry[1], entry[2]),
					path = p.path,
					bufnr = p.bufnr,
					dir = p.dir,
					file = p.file,
				}
			end,
		}
	end
	return p
end

function B.jump(p, line, split)
	p = B.get_path(p)
	if not p then
		return
	end

	if p.dir then
		vim.cmd(sprintf(":Lexplore %s | vert size 40", sel.path))
	elseif not p.bufnr then
		p = p.path
		if split == "s" then
			vim.cmd(":split " .. p)
		elseif split == "v" then
			vim.cmd(":vsplit " .. p)
		elseif split == "t" then
			vim.cmd(":tabnew " .. p)
		else
			vim.cmd(":e " .. p)
		end
		if p.lines and p.lines[line] then
			vim.cmd(":normal! " .. line .. "G")
		end
	elseif p.bufnr then
		local bufnr = p.bufnr
		if split == "s" then
			vim.cmd(":split | b " .. bufnr)
		elseif split == "v" then
			vim.cmd(":vsplit | b " .. bufnr)
		elseif split == "t" then
			vim.cmd(":tabnew | b " .. bufnr)
		else
			vim.cmd(":b " .. bufnr)
		end
		if p.lines and p.lines[line] then
			vim.cmd(":normal! " .. line .. "G")
		end
	elseif p.dir then
		vim.cmd(sprintf(":Lexplore %s | vert resize 40", p.path))
	end
end

function B.delete_all()
	if not path.exists(Bookmarks.dest) then
		return
	end
	vim.fn.system({ "rm", Bookmarks.dest })
end

function B.create_picker(p, remover)
	p = B.get_path(p)
	if not p then
		return
	end
	local _ = utils.telescope.load()
	local mod = _.create_actions_mod()
	local ls = B.list(p.path, true)
	if not ls then
		return
	end
	local default_action

	if remover then
		default_action = function(prompt_bufnr)
			local sel = _.get_selected(prompt_bufnr)[1]
			B.remove(sel.path, sel.line)
		end
	else
		default_action = function(prompt_bufnr)
			local sel = _.get_selected(prompt_bufnr)[1]
			B.jump(sel.path, sel.line, "v")
		end
	end

	function mod.remove(sel)
		B.remove(sel.path, sel.line)
	end

	function mod.split(sel)
		B.jump(sel.path, sel.line, "s")
	end

	function mod.tabnew(sel)
		B.jump(sel.path, sel.line, "t")
	end

	function mod.vsplit(sel)
		B.jump(sel.path, sel.line, "s")
	end

	return _.new(ls, {
		default_action,
		{ "n", "x", mod.remove },
		{ "n", "s", mod.split },
		{ "n", "v", mod.vsplit },
		{ "n", "t", mod.tabnew },
	}, {
		prompt_title = "Bookmark: " .. p.path,
	})
end

function B.create_main_picker()
	local ls = B.list(false, true)
	if not ls then
		return
	end
	local _ = utils.telescope.load()
	local mod = _.create_actions_mod()

	local function default_action(prompt_bufnr)
		local sel = _.get_selected(prompt_bufnr)[1]
		if sel.dir then
			vim.cmd(sprintf(":Lexplore %s | vert resize 40", sel.path))
		else
			local picker = B.create_picker(sel.path)
			if picker then
				picker:find()
			end
		end
	end

	function mod.remove(sel)
		B.create_picker(sel.path, true):find()
	end

	return _.new(ls, {
		default_action,
		{ "n", "x", mod.remove },
	})
end
