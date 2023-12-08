require("core.utils.kbd")

bookmark = bookmark or module("bookmark")
bookmark.path = path.join(os.getenv("HOME"), ".bookmarks.json")
bookmark.bookmarks = bookmark.bookmarks or {}
local bookmarks = bookmark.bookmarks

function string_keys(x)
	local out = {}

	for key, value in pairs(x) do
		local context = value.context

		if context then
			local new = {}

			for key, value in pairs(context) do
				new[tostring(key)] = value
			end

			value.context = new
		end

		out[key] = value
	end

	return out
end

local function from_string_keys(parsed_json)
	local out = {}

	for key, value in pairs(parsed_json) do
		local context = value.context

		if context then
			local new = {}

			for K, V in pairs(context) do
				new[tonumber(K)] = V
			end

			value.context = new
		end

		out[key] = value
	end

	return out
end

function bookmark.init()
	bookmark.bookmarks = bookmark.load()
	return bookmark.bookmarks
end

function bookmark.load()
	s = file.read(bookmark.path) or "{}"
	s = from_string_keys(json.decode(s))

	bookmark.bookmarks = s
	return s
end

function bookmark.save()
	local bookmarks = bookmark.bookmarks
	file.write(bookmark.path, json.encode(string_keys(bookmarks)))

	bookmark.load()

	return bookmark.bookmarks
end

function bookmark.add(file_path, lines, desc)
	local obj = bookmark.bookmarks[file_path] or { context = {} }
	local now = os.time()
	local isfile = path.isfile(file_path)
	local isdir = path.isdir(file_path)

	if not isfile and not isdir then
		error(file_path .. " is neither a binary file or a directory")
	elseif lines and isdir then
		error(file_path .. " cannot use linesnum with a directory")
	elseif lines then
		context = bookmark.get_context(file_path, lines)
	end

	obj.creation_time = now
	dict.merge(obj.context, tolist(lines))
	obj.file = isfile
	obj.dir = isdir
	obj.desc = desc
	obj.path = file_path

	for key, _ in pairs(obj.context) do
		obj.context[key] = bookmark.get_context(file_path, key)
	end

	bookmark.bookmarks[file_path] = obj
	return obj
end

function bookmark.del(file_path, lines)
	if not bookmark.bookmarks[file_path] then
		return
	end

	local obj = bookmark.bookmarks[file_path]
	if lines then
		local context = obj.context
		for _, line in ipairs(tolist(lines)) do
			context[line] = nil
		end
	else
		bookmark.bookmarks[file_path] = nil
	end

	return obj
end

function bookmark.add_and_save(file_path, lines, desc)
	local ok = bookmark.add(file_path, lines, desc)
	if not ok then
		return
	end

	bookmark.save()

	return ok
end

function bookmark.del_and_save(file_path, lines)
	local obj = bookmark.del(file_path, lines)
	if not obj then
		return
	end

	bookmark.save()

	return obj
end

function bookmark.get_context(file_path, line)
	data = split(file.read(file_path), "\n")

	if line > #data or #data < 1 then
		error(sprintf("invalid line %d provided for %s", line, file_path))
	end

	return data[line]
end

function bookmark.open(file_path, line)
	if isstring(line) then
		split = line
	end

	if path.isdir(file_path) then
		vim.cmd(":e! " .. file_path)
	elseif path.isfile(file_path) then
		local bufnr = buffer.bufadd(file_path)
		buffer.open(bufnr)

		if line then
			if buffer.current() == file_path then
				vim.cmd(":normal! " .. line .. "Gzz")
			else
				buffer.call(bufnr, function()
					vim.cmd(":normal! " .. line .. "Gzz")
				end)
			end
		end
	end
end

function bookmark.picker_results(file_path)
	local bookmarks = bookmark.bookmarks

	if isempty(bookmarks) then
		return
	end

	if not file_path then
		return {
			results = keys(bookmarks),
			entry_maker = function(entry)
				local obj = bookmarks[entry]

				return {
					display = entry,
					value = obj,
					path = obj.path,
					file = obj.file,
					dir = obj.dir,
					ordinal = entry,
				}
			end,
		}
	end

	local obj = bookmark.bookmarks[file_path]

	if not obj then
		return
	elseif obj.context and isempty(obj.context) then
		return
	end

	return {
		results = keys(obj.context),
		entry_maker = function(linenum)
			return {
				display = sprintf("%d | %s", linenum, obj.context[linenum]),
				value = linenum,
				path = obj.path,
				ordinal = linenum,
			}
		end,
	}
end

function bookmark.create_line_picker(file_path)
	local obj = bookmark.bookmarks[file_path]
	local fail = not obj or obj.dir or not obj.context or isempty(obj.context)
	if fail then
		return
	end

	local t = load_telescope()
	local line_mod = {}

	function line_mod.default_action(sel)
		local obj = sel[1]
		local linenum = obj.value
		local file_path = obj.path

		bookmark.open(file_path, linenum, "s")
	end

	function line_mod.del(sel)
		list.each(sel, function(obj)
			local linenum = value.value
			local file_path = obj.path

			bookmark.del_and_save(file_path, linenum)
		end)
	end

	local context = bookmark.picker_results(obj.path)

	local picker = t.create(context, {
		line_mod.default_action,
		{ "n", "x", line_mod.del },
	}, {
		prompt_title = "bookmarked lines",
	})

	return picker
end

function bookmark.run_line_picker(file_path)
	local picker = bookmark.create_line_picker(file_path)
	if not picker then
		return
	end

	picker:find()
	return true
end

function bookmark.create_picker()
	local results = bookmark.picker_results()

	if not results then
		return
	end

	local t = load_telescope()
	local mod = {}

	function mod.default_action(sel)
		local obj = sel[1]

		if obj.file then
			local line_picker = bookmark.create_line_picker(obj.path)
			if line_picker then
				line_picker:find()
			end
		else
			bookmark.open(obj.path, "s")
		end
	end

	function mod.del(sel)
		list.each(sel, function(obj)
			bookmark.del_and_save(obj.path)
			say("removed bookmark " .. obj.path)
		end)
	end

	return t.create(results, { mod.default_action, { "n", "x", mod.del } }, { prompt_title = "bookmarks" })
end

function bookmark.run_picker()
	local picker = bookmark.create_picker()
	if not picker then
		return
	end

	picker:find()
	return true
end

function bookmark.reset()
	if path.exists(bookmark.path) then
		file.delete(bookmark.path)
		return true
	end
end

function bookmark.create_dwim_picker()
	local bufname = buffer.name()
	local obj = bookmark.bookmarks[bufname]

	if not obj or (obj.context and isempty(obj.context)) then
		return bookmark.create_picker()
	else
		return bookmark.create_line_picker(obj.path)
	end
end

function bookmark.run_dwim_picker()
	local picker = bookmark.create_dwim_picker()
	if picker then
		picker:find()
	end

	return true
end

return bookmark
