bookmark = module.new "bookmark"

bookmark.Bookmark = struct.new('Bookmark', {'path', 'buffer', 'file', 'dir', 'lines'})

bookmark.exception = exception.new {
    invalid_path = "expected valid path",
    corrupted = "bookmarks could not be read",
    cannot_save = "cannot save bookmarks",
}

bookmark.bookmarks = {}
bookmark.save_on_exit = true
bookmark.load_on_open = true
bookmark.save_path = vim.fn.stdpath "data" .. "/bookmarks.lua"

--------------------------------------------------
local function resolve_path(p)
    validate { path = { is { "string", "number" }, p } }

    if is_string(p) then p = vim.fs.normalize(p) end
    if p == 0 then p = vim.fn.bufnr() end

    local is_buffer = vim.fn.bufexists(p) ~= 0
    local is_file = is_a.string(p) and path.exists(p)

    if not is_buffer and not is_file then return end

    if is_buffer then
        local bufnr = vim.fn.bufnr()
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if #bufname == 0 then return end

        if path.isdir(bufname) then
            p = { dir = true, path = bufname }
        else
            local loaded = vim.fn.bufloaded(bufnr) == 1
            if not loaded then return end
            local listed = vim.api.nvim_buf_get_option(bufnr, "buflisted")
            if not listed then return end
            p = {
                bufnr = bufnr,
                path = bufname,
                dir = false,
                file = true,
                lines = {},
            }
        end
    elseif path.isdir(p) then
        p = {
            dir = true,
            file = false,
            path = path.abspath(p),
        }
    else
        p = {
            dir = false,
            file = true,
            path = p,
            lines = {},
        }
    end

    return p
end

function bookmark.get(p, line)
    exists = bookmark.bookmarks[p]
    if not exists then
        p = resolve_path(p)
        if not p then return end
        p = p.path
    end

    local exists = bookmark.bookmarks[p]

    if exists and line then
        return exists.lines[line]
    elseif exists then
        return exists
    end
end

function bookmark.new(p)
    local _p = resolve_path(p)
    bookmark.exception.invalid_path:assert(_p, p)

    local st = Bookmark {}

    dict.merge(self, _p)
    dict.update(bookmark.bookmarks, _p.path, self)
end

local function file_line_count(p) return #(file.read(p):split "\n") end

local function buffer_line_count(bufnr)
    return vim.api.nvim_buf_line_count(bufnr)
end

local function file_line(p, line) return file.read(p):split("\n")[line] end

local function buffer_line(bufnr, line)
    return vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1]
end

function bookmark:update_context()
    if self.dir then return end
    if dict.isblank(self.lines) then return end

    local n
    if self.bufnr then
        n = buffer_line_count(self.bufnr)
    elseif self.path then
        n = file_line_count(self.path)
    end

    dict.each(self.lines, function(line, _)
        if line > n or line < 1 then
            self.lines[line] = nil
        else
            self.lines[line] = self.bufnr and buffer_line(self.bufnr, line)
                or file_line(self.path, line)
        end
    end)
end

function bookmark:open(line)
    if self.bufnr then
        vim.cmd(":b " .. self.path)
    else
        vim.cmd(":e " .. self.path)
    end

    if line then vim.cmd(":normal! " .. tostring(line) .. "G") end
end

function bookmark:remove(line)
    local obj = self.lines[line]
    if obj then
        self.lines[line] = nil
        return obj
    end
    return false
end

function bookmark:delete() bookmark.bookmarks[self.path] = nil end

function bookmark:list(telescope)
    if self:is_dir() then
        return false, self.path .. " is a directory"
    elseif dict.isblank(self.lines) then
        return false, self.path .. " does not have lines"
    end

    if telescope then
        return {
            results = dict.items(self.lines),
            entry_maker = function(entry)
                return {
                    ordinal = entry[1],
                    line = entry[1],
                    context = entry[2],
                    display = sprintf("%-4d|%s", entry[1], entry[2]),
                    path = self.path,
                    bufnr = self.bufnr,
                    dir = self.dir,
                    file = self.file,
                }
            end,
        }
    end

    return self.lines
end

function bookmark:add(line)
    line = line or "."
    validate.line(function(x)
        local msg = "'.' for current line or line number"
        local ok = x == "." or is_a.number(x)
        if not ok then return ok, msg end
        return true
    end, line)

    if buffer.exists(self.path) then self.bufnr = buffer.bufnr(self.path) end

    if self.bufnr and line == "." then
        local winid = vim.fn.bufwinid(self.bufnr)
        if winid ~= -1 then
            line = vim.api.nvim_buf_call(
                self.bufnr,
                function() return vim.fn.getpos(".")[2] end
            )
        else
            return false, self.path .. " is not visible"
        end
    elseif self.dir then
        return false, self.path .. " is a directory"
    end

    local n = self.bufnr and buffer_line_count(self.bufnr)
        or file_line_count(self.path)

    if line > n or line < 1 then
        return false, "must be 1 <= linenum <= path_line_count"
    end

    self.lines[line] = self.bufnr and buffer_line(self.bufnr, line)
        or file_line(self.path)

    return self.lines[line]
end

function bookmark:is_dir()
    self.dir = path.isdir(self.path)
    return self.dir
end

function bookmark:is_buffer() return self.bufnr end

function bookmark:is_invalid()
    if not buffer.exists(self.bufnr) then self.bufnr = nil end

    if not buffer.exists(self.path) then return true end

    return false
end

function bookmark:autoremove()
    if self:is_invalid() then self:delete() end
end

function bookmark:jump(line, split)
    local bufnr = buffer.bufnr(self.path)
    if bufnr then self.bufnr = bufnr end

    if self.dir then
        vim.cmd(":Lexplore " .. self.path)
        vim.cmd ":vert resize 40"
    -- vim.cmd()
    elseif not self.bufnr then
        self = self.path
        if split == "s" then
            vim.cmd(":split " .. self)
        elseif split == "v" then
            vim.cmd(":vsplit " .. self)
        elseif split == "t" then
            vim.cmd(":tabnew " .. self)
        else
            vim.cmd(":e " .. self)
        end
        if self.lines and self.lines[line] then
            vim.cmd(":normal! " .. line .. "G")
        end
    elseif self.bufnr then
        local bufnr = self.bufnr
        if split == "s" then
            vim.cmd(":split | b " .. bufnr)
        elseif split == "v" then
            vim.cmd(":vsplit | b " .. bufnr)
        elseif split == "t" then
            vim.cmd(":tabnew | b " .. bufnr)
        else
            vim.cmd(":b " .. bufnr)
        end
        if self.lines and self.lines[line] then
            vim.cmd(":normal! " .. line .. "G")
        end
    elseif self.dir then
        vim.cmd(sprintf(":Lexplore %s | vert resize 40", self.path))
    end
end

function bookmark.jump_to_path(p, split)
    local obj = bookmark.exists(p)
    if not obj then return end
    obj:jump(nil, split)
end

function bookmark.jump_to_line(p, line, split)
    local obj = bookmark.exists(p)
    if not obj then return end
    obj:jump(line, split)
end

function bookmark:create_picker(remover)
    local _ = utils.telescope.load()
    local mod = _.create_actions_mod()
    local ls = self:list(true)
    if not ls then return end
    local default_action
    local title

    if remover then
        title = "[Remover] bookmarks for " .. self.path

        default_action = function(prompt_bufnr)
            array.each(
                _.get_selected(prompt_bufnr),
                function(sel) self:remove(sel.line) end
            )
        end
    else
        title = "bookmarks for " .. self.path

        default_action = function(prompt_bufnr)
            local sel = _.get_selected(prompt_bufnr)[1]
            self:open(sel.line)
        end
    end

    function mod.remove(sel) self:remove(sel.line) end
    function mod.split(sel) self:jump(sel.line, "s") end
    function mod.tabnew(sel) self:jump(sel.line, "t") end
    function mod.vsplit(sel) self:jump(sel.line, "v") end

    return _.new(ls, {
        default_action,
        { "n", "x", mod.remove },
        { "n", "s", mod.split },
        { "n", "v", mod.vsplit },
        { "n", "t", mod.tabnew },
    }, {
        prompt_title = title,
    })
end

function bookmark.list_all(telescope)
    local ks = dict.keys(bookmark.bookmarks)

    if #ks == 0 then
        return
    elseif not telescope then
        local out = {}
        array.each(
            ks,
            function(bookmark_path)
                out[bookmark_path] = bookmark.bookmarks[bookmark_path]:list()
            end
        )

        return out
    end

    return ks
end

function bookmark.create_main_picker(remover)
    local ls = bookmark.list_all(true)
    if not ls then return end
    local _ = utils.telescope.load()
    local mod = _.create_actions_mod()

    local function get_obj(k)
        local out = bookmark.bookmarks[k]
        if not out or not is_class(out) then out = bookmark(k) end
        return out
    end

    local function remove(sel)
        local obj = get_obj(sel[1])
        local lines = obj:list()
        if not lines then return obj:delete() end
        obj:create_picker(remove):find()
    end

    function mod.remove(sel) remove(sel) end

    function mod.marks(sel)
        local obj = get_obj(sel[1])
        local picker = obj:create_picker()
        if not picker then
            if obj.bufnr then
                vim.cmd("b " .. sel[1])
            else
                vim.cmd("e " .. sel[1])
            end
        else
            picker:find()
        end
    end

    local function default_action(prompt_bufnr)
        local sel = _.get_selected(prompt_bufnr)[1]
        if remover then
            remove(sel)
        else
            local obj = get_obj(sel[1])
            obj:jump()
        end
    end

    local title
    if remover then
        title = "[Remover] All bookmarks"
    else
        title = "All bookmarks"
    end

    return _.create_picker(ls, {
        default_action,
        { "n", "x", mod.remove },
        { "n", "m", mod.marks },
    }, {
        prompt_title = title,
    })
end

function bookmark.add_path(p)
    local obj = bookmark.exists(p)
    if not obj then obj = bookmark(p) end

    return obj
end

function bookmark.add_line(p, line)
    if not line then return bookmark.add_path(line) end

    local obj = bookmark.add_path(p)
    if not obj then return end

    obj:update_context()
    obj:add(line)

    return obj
end

function bookmark.remove_line(p, line)
    local obj = bookmark.exists(p)
    if obj then obj:remove(line) end

    return obj
end

function bookmark.remove_path(p)
    if bookmark.bookmarkss[p] then
        bookmark.bookmarkss[p] = nil
    else
        p = resolve_path(p)
        if not p then return end
        bookmark.bookmarks[p.path] = nil
    end
end

function bookmark.clean()
    dict.each(bookmark.bookmarks, function(_, obj)
        if not obj:is_invalid() then
            obj:update_context()
        else
            obj:autoremove()
        end
    end)
end

function bookmark.exists(p)
    p = resolve_path(p)
    p = p and bookmark.bookmarks[p.path]

    return p or false
end

function bookmark.remove_current_buffer(line)
    if line then return bookmark.remove_line(vim.fn.bufnr(), line) end

    return bookmark.remove_path(vim.fn.bufnr())
end

function bookmark.add_current_buffer(line)
    return bookmark.add_line(vim.fn.bufnr(), line)
end

function bookmark.list_buffers()
    local buffers = array.grep(vim.fn.getbufinfo(), function(buf)
        local buftype = vim.api.nvim_buf_get_option(buf.bufnr, "buftype")
        if buftype == "nofile" or buf.listed == 0 or buf.loaded == 0 then
            return false
        end
        if #buf.name == 0 then return false end

        return true
    end)

    return array.map(buffers, function(buf) return buf.name end)
end

function bookmark.save()
    file.write(
        bookmark.save_path,
        "return "
            .. dump(dict.map(
                bookmark.bookmarks,
                function(_, obj)
                    return {
                        path = obj.path,
                        file = obj.file,
                        dir = obj.dir,
                        lines = obj.lines,
                    }
                end
            ))
    )
end

function bookmark.load()
    local ls = file.read(bookmark.save_path)
    if not ls then return end

    local ok, msg = pcall(loadstring, ls)
    if not ok then return end

    bookmark.bookmarks = {}
    local bookmarks = bookmark.bookmarks
    ls = msg()
    if not ls then return end

    dict.each(ls, function(k, obj)
        if resolve_path(k) then
            bookmarks[k] = bookmark(k)
            bookmarks[k].lines = obj.lines
        end
    end)

    return ls
end

function bookmark.create_current_buffer_picker(remove)
    local exists = bookmark.get(vim.fn.bufnr())
    if not exists then return end
    local picker = exists:create_picker(remove)
    if picker then return picker end
end

function bookmark:print()
    if self.dir then return pp(sprintf("Directory: " .. self.path)) end

    local display = {}
    if self.bufnr then
        display[1] = sprintf("Buffer (%d): %s", self.bufnr, self.path)
    else
        display[1] = sprintf("File: %s", self.path)
    end

    if self.lines and not dict.isblank(self.lines) then
        local i = 2
        dict.each(self.lines, function(linenum, line)
            display[i] = sprintf("%-4d ⎥%s", linenum, line)
            i = i + 1
        end)
    end

    pp(array.join(display, "\n"))
end

function bookmark.print_all()
    dict.each(bookmark.bookmarks, function(_, obj)
        obj:print()
        print()
    end)
end

function bookmark.reset()
    bookmark.BOOKMARK = {}
    return vim.fn.system { "rm", bookmark.save_path }
end

