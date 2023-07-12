bookmark = bookmark or { bookmarks = {} }
local mod = {}

function bookmark.resolve(bufnr_or_fname)
    validate.bufnr_or_fname(is { "string", "number" }, bufnr_or_fname)

    local function get_type(p)
        if is_a.number(p) then
            if not buffer.exists(p) then
                error "invalid_buffer"
            end
            return buffer.name(p), "buffer"
        else
            local bufnr = buffer.bufnr(p)

            if bufnr then
                return bookmark.resolve(bufnr)
            end
            if not path.exists(p) then
                error "invalid_path"
            end

            return path.abspath(p), "path"
        end
    end

    local function get_path_type(p)
        local tp
        p, tp = get_type(p)

        if path.isdir(p) then
            tp = { tp, "dir" }
        else
            tp = { tp, "file" }
        end

        return p, tp
    end

    return get_path_type(bufnr_or_fname)
end

function bookmark.get(bufnr_or_fname)
    local p, _ = bookmark.resolve(bufnr_or_fname)
    return bookmark.bookmarks[p]
end

function bookmark.line_count(bufnr_or_fname)
    local p, tp = bookmark.resolve(bufnr_or_fname)
    if tp == "dir" then
        return
    end

    if tp == "buffer" then
        return buffer.linecount(buffer.bufnr(p))
    end

    return vim.fn.systemlist("wc -l " .. p)[1]
end

function bookmark.prune()
    dict.each(bookmark.bookmarks, function(p, obj)
        if not path.exists(p) then
            bookmark.bookmarks[p] = nil
        elseif obj.path_type ~= "dir" then
            local lc = bookmark.line_count(p)
            dict.each(obj.lines, function(linenum, _) end)
        end
    end)
end
