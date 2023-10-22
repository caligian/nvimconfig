require 'core.utils.kbd'

Bookmark = Bookmark or module "Bookmark"
Bookmark.path = path.join(os.getenv "HOME", ".bookmarks.json")
Bookmark.bookmarks = Bookmark.bookmarks or {}
local bookmarks = Bookmark.bookmarks

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

function from_string_keys(parsed_json)
    local out = {}

    for key, value in pairs(parsed_json) do
        local context = value.context

        if context then
            local new = {}

            for key, value in pairs(context) do
                new[tonumber(key)] = value
            end

            value.context = new
        end

        out[key] = value
    end

    return out
end

function Bookmark.init()
    Bookmark.bookmarks = Bookmark.load()
    return Bookmark.bookmarks
end

function Bookmark.load()
    s = file.read(Bookmark.path) or "{}"
    s = from_string_keys(json.decode(s))

    Bookmark.bookmarks = s
    return s
end

function Bookmark.save()
    local bookmarks = Bookmark.bookmarks
    file.write(Bookmark.path, json.encode(string_keys(bookmarks)))

    Bookmark.load()

    return Bookmark.bookmarks
end

function Bookmark.add(file_path, lines, desc)
    local obj = Bookmark.bookmarks[file_path] or { context = {} }
    local now = os.time()
    local context
    local isfile = path.isfile(file_path)
    local isdir = path.isdir(file_path)

    if not isfile and not isdir then
        error(file_path .. " is neither a binary file or a directory")
    elseif lines and isdir then
        error(file_path .. " cannot use linesnum with a directory")
    elseif lines then
        context = Bookmark.get_context(file_path, lines)
    end

    obj.creation_time = now
    merge(obj.context, array.to_dict(to_array(lines)))
    obj.file = isfile
    obj.dir = isdir
    obj.desc = desc
    obj.path = file_path

    for key, _ in pairs(obj.context) do
        obj.context[key] = Bookmark.get_context(file_path, key)
    end

    Bookmark.bookmarks[file_path] = obj
    return obj
end

function Bookmark.del(file_path, lines)
    if not Bookmark.bookmarks[file_path] then
        return
    end

    local obj = Bookmark.bookmarks[file_path]
    if lines then
        local context = obj.context
        for _, line in ipairs(to_array(lines)) do
            context[line] = nil
        end
    else
        Bookmark.bookmarks[file_path] = nil
    end

    return obj
end

function Bookmark.add_and_save(file_path, lines, desc)
    local ok = Bookmark.add(file_path, lines, desc)
    if not ok then
        return
    end

    Bookmark.save()

    return ok
end

function Bookmark.del_and_save(file_path, lines)
    local obj = Bookmark.del(file_path, lines)
    if not obj then
        return
    end

    Bookmark.save()

    return obj
end

function Bookmark.get_context(file_path, line)
    data = string.split(file.read(file_path), "\n")

    if line > #data or #data < 1 then
        error(sprintf("invalid line %d provided for %s", line, file_path))
    end

    return data[line]
end

function Bookmark.open(file_path, line)
    if is_string(line) then
        split = line
    end

    if path.isdir(file_path) then
        vim.cmd(':e! ' .. file_path)
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

function Bookmark.picker_results(file_path)
    local bookmarks = Bookmark.bookmarks

    if is_empty(bookmarks) then
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

    local obj = Bookmark.bookmarks[file_path]

    if not obj then
        return
    elseif obj.context and is_empty(obj.context) then
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

function Bookmark.create_line_picker(file_path)
    local obj = Bookmark.bookmarks[file_path]
    local fail = not obj or obj.dir or not obj.context or is_empty(obj.context)
    if fail then return end

    local t = load_telescope()
    local line_mod = {}

    function line_mod.default_action(sel)
        local obj = sel[1]
        local linenum = obj.value
        local file_path = obj.path

        Bookmark.open(file_path, linenum, "s")
    end

    function line_mod.del(sel)
        each(sel, function(obj)
            local linenum = value.value
            local file_path = obj.path

            Bookmark.del_and_save(file_path, linenum)
        end)
    end

    local context = Bookmark.picker_results(obj.path)

    local picker = t.create(context, {
        line_mod.default_action,
        { "n", "x", line_mod.del },
    }, {
        prompt_title = "Bookmarked lines",
    })

    return picker
end

function Bookmark.run_line_picker(file_path)
    local picker = Bookmark.create_line_picker(file_path)
    if not picker then return end

    picker:find()
    return true
end

function Bookmark.create_picker()
    local results = Bookmark.picker_results()

    if not results then
        return
    end

    local t = load_telescope()
    local mod = {}

    function mod.default_action(sel)
        local obj = sel[1]

        if obj.file then
            local line_picker = Bookmark.create_line_picker(obj.path)
            if line_picker then
                line_picker:find()
            end
        else
            Bookmark.open(obj.path, 's')
        end
    end

    function mod.del(sel)
        each(sel, function(obj)
            Bookmark.del_and_save(obj.path)
            say("removed bookmark " .. obj.path)
        end)
    end

    return t.create(results, { mod.default_action, { "n", "x", mod.del } }, { prompt_title = "Bookmarks" })
end

function Bookmark.run_picker()
    local picker = Bookmark.create_picker()
    if not picker then
        return
    end

    picker:find()
    return true
end

function Bookmark.reset()
    if path.exists(Bookmark.path) then
        file.delete(Bookmark.path)
        return true
    end
end

function Bookmark.create_dwim_picker()
    local bufname = buffer.name()
    local obj = Bookmark.bookmarks[bufname]

    if not obj or (obj.context and is_empty(obj.context)) then
        return Bookmark.create_picker()
    else
        return Bookmark.create_line_picker(obj.path)
    end
end

function Bookmark.run_dwim_picker()
    local picker = Bookmark.create_dwim_picker()
    if picker then picker:find() end

    return true
end

return Bookmark
