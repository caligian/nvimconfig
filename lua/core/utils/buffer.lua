--- Common buffer operations. Many of them are simply aliases to their vim equivalents
-- requires: Autocmd, Keybinding
-- @module buffer
require "core.utils.win"
require "core.utils.autocmd"
require "core.utils.kbd"

buffer = { float = {} }
local floatmt = {}
local float = setmetatable(buffer.float, floatmt)
local is_string_or_table = is { "string", "array" }

--- Raised when buffer index is invalid for an operation
buffer.InvalidBufferException = exception "invalid buffer expr"

--- Add buffer by name or return existing buffer index. ':help bufadd()'
-- @function buffer.bufadd
-- @tparam number|string expr buffer index or name
-- @treturn number 0 on error, bufnr otherwise
buffer.bufadd = vim.fn.bufadd

function buffer.bufnr(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    bufnr = vim.fn.bufnr(bufnr)
    if bufnr == -1 then
        return false
    end

    return bufnr
end

buffer.current = buffer.bufnr

--- Send keystrokes to buffer. `:help feedkeys()`
-- @tparam number bufnr
-- @tparam string keys
-- @tparam ?string flags
-- @treturn false if invalid buffer is provided
function buffer.feedkeys(bufnr, keys, flags)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    buffer.call(bufnr, function()
        vim.cmd("normal! " .. keys)
    end)

    return true
end

--- Does buffer exists?
-- @tparam number bufnr buffer index
-- @treturn boolean success status
function buffer.exists(bufnr)
    return vim.fn.bufexists(bufnr) ~= 0
end

--- Unload and delete buffer
-- @tparam number bufnr buffer index
-- @treturn boolean success status
function buffer.wipeout(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    vim.api.nvim_buf_delete(bufnr, { force = true })
    return true
end

--- Unload and delete buffer
-- @function buffer.delete
-- @tparam number bufnr buffer index
-- @treturn boolean success status
buffer.delete = buffer.wipeout

function buffer.unload(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    vim.api.nvim_buf_delete(bufnr, { unload = true })
    return true
end

function buffer.getmap(bufnr, mode)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    return vim.api.nvim_buf_get_keymap(bufnr, mode)
end

function buffer.winnr(bufnr)
    bufnr = bufnr or buffer.bufnr()
    local winnr = vim.fn.bufwinnr(bufnr)
    if winnr == -1 then
        return false
    end

    return winnr
end

function buffer.winid(bufnr)
    local winid = vim.fn.bufwinid(bufnr)
    if winid == -1 then
        return false
    end

    return winid
end

--- Get buffer option
-- @tparam string opt Name of the option
-- @treturn any
function buffer.option(bufnr, opt)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    local _, out = pcall(vim.api.nvim_buf_get_option, bufnr, opt)
    if out ~= nil then
        return out
    end
end

--- Get buffer option
-- @tparam string var Name of the variable
-- @treturn any
function buffer.var(bufnr, var)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    local ok, out = pcall(vim.api.nvim_buf_get_var, bufnr, var)
    if ok then
        return out
    end
end

function buffer.setvar(bufnr, k, v)
    validate {
        key = { is { "string", "dict" }, k },
    }

    bufnr = bufnr or buffer.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    if is_a.string(k) then
        vim.api.nvim_buf_set_var(bufnr, k, v)
    else
        dict.each(k, function(key, value)
            buffer.setvar(bufnr, key, value)
        end)
    end

    return true
end

--- Set buffer option
-- @tparam number bufnr
-- @tparam string k option name
-- @tparam any v value
function buffer.setoption(bufnr, k, v)
    validate {
        key = { is { "string", "dict" }, k },
    }

    bufnr = bufnr or buffer.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    if is_a.string(k) then
        vim.api.nvim_buf_set_option(bufnr, k, v)
    else
        dict.each(k, function(key, value)
            buffer.setoption(bufnr, key, value)
        end)
    end

    return true
end

--- Make a new buffer local mapping.
-- @tparam number bufnr
-- @see Keybinding.map
-- @treturn Keybinding
function buffer.map(bufnr, mode, lhs, callback, opts)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    opts = opts or {}
    opts.buffer = bufnr

    return kbd.map(mode, lhs, callback, opts)
end

--- Make a new buffer local nonrecursive mapping.
-- @tparam number bufnr
-- @see Keybinding.noremap
-- @treturn Keybinding
function buffer.noremap(bufnr, mode, lhs, callback, opts)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    opts = opts or {}
    if is_a.s(opts) then
        opts = { desc = opts }
    end
    opts.buffer = bufnr
    opts.noremap = true

    return buffer.map(bufnr, mode, lhs, callback, opts)
end

--- Create a buffer local autocommand. The  pattern will be automatically set to '<buffer=%d>'
-- @see autocmd._init
function buffer.hook(bufnr, event, callback, opts)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    opts = opts or {}

    return autocmd.map(
        event,
        dict.merge(opts, {
            pattern = sprintf("<buffer=%d>", bufnr),
            callback = callback,
        })
    )
end

function buffer.autocmd(...)
    return buffer.hook(...)
end

--- Hide current buffer if visible
---  Is buffer visible?
--  @return boolean
function buffer.isvisible(bufnr)
    return vim.fn.bufwinid(bufnr) ~= -1
end

--- Get buffer lines
-- @param startrow Starting row
-- @param tillrow Ending row
-- @return table
function buffer.lines(bufnr, startrow, tillrow)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    startrow = startrow or 0
    tillrow = tillrow or -1

    validate {
        start_row = { "number", startrow },
        end_row = { "number", tillrow },
    }

    return vim.api.nvim_buf_get_lines(bufnr, startrow, tillrow, false)
end

--- Get buffer text
-- @tparam number start_row Starting row
-- @tparam number start_col Starting column
-- @tparam number end_row Ending row
-- @tparam number end_col Ending column
-- @tparam[opt] dict Options
-- @return
function buffer.text(bufnr, start_row, start_col, end_row, end_col, opts)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    return vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, opts or {})
end

function buffer.kbd(bufnr, opts)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    opts.buffer = bufnr
    return Keybinding.bind(opts)
end

--- Set buffer lines
-- @param startrow Starting row
-- @param endrow Ending row
-- @param repl Replacement line[s]
function buffer.setlines(bufnr, startrow, endrow, repl)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    assert(startrow)
    assert(endrow)

    if is_a(repl, "string") then
        repl = vim.split(repl, "[\n\r]")
    end

    vim.api.nvim_buf_set_lines(bufnr, startrow, endrow, false, repl)

    return true
end

--- Set buffer text
-- @tparam table start Should be table containing start row and col
-- @tparam table till Should be table containing end row and col
-- @tparam string|table repl Replacement text
function buffer.settext(bufnr, start, till, repl)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    validate.startind("array", start)
    validate.endind("array", till)

    vim.api.nvim_buf_set_text(self.bufnr, start[1], till[1], start[2], till[2], repl)

    return true
end

--- Switch to this buffer
function buffer.open(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    vim.cmd("b " .. bufnr)
    return true
end

--- Load buffer
function buffer.load(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    if vim.fn.bufloaded(bufnr) == 1 then
        return true
    else
        vim.fn.bufload(bufnr)
    end

    return true
end

--- Call callback on buffer and return result
-- @param cb Function to call in this buffer
-- @return self
function buffer.call(bufnr, cb)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    return vim.api.nvim_buf_call(bufnr, cb)
end

function buffer.linecount(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    return vim.api.nvim_buf_line_count(bufnr)
end

--- Return current linenumber
-- @return number
function buffer.linenum(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    return buffer.call(bufnr, function()
        return vim.fn.getpos(".")[2]
    end)
end

function buffer.listed(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    return vim.fn.buflisted(bufnr) ~= 0
end

function buffer.info(bufnr, all)
    local function to_dict(lst)
        local new = {}
        array.each(lst, function(info)
            new[info.bufnr] = info
        end)

        return new, info
    end

    if is_a.dict(bufnr) then
        return to_dict(vim.fn.getbufinfo(bufnr))
    end

    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    if all then
        return to_dict(vim.fn.getbufinfo(bufnr))
    else
        return to_dict(vim.fn.getbufinfo(bufnr)[1])
    end
end

function buffer.list(criteria, opts)
    local found = buffer.info(criteria)
    local out = dict.keys(found)

    if #out == 0 then
        return
    end
    if not opts then
        return out
    end

    opts = opts or {}
    local filter = opts.filter
    local remove_empty = opts.remove_empty
    local apply = opts.apply
    local keep_dict = opts.dict
    local callback = opts.callback
    local name = opts.name

    if name then
        out = array.map(out, buffer.name)
    end

    if remove_empty then
        out = array.grep(out, function(x)
            if is_a.string(x) then
                return #x > 0
            else
                return #buffer.name(x) > 0
            end
        end)
    end

    if filter then
        out = array.grep(out, filter)
    end

    if apply then
        out = array.map(out, apply)
    end

    if callback then
        callback(out)
    end

    if keep_dict then
        local info = {}
        array.each(out, function(bufnr)
            info[bufnr] = found[bufnr]
        end)

        return info
    end

    return out
end

function buffer.string(bufnr)
    return table.concat(buffer.lines(bufnr, 0, -1), "\n")
end

function buffer.getbuffer(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    return buffer.lines(bufnr, 0, -1)
end

function buffer.setbuffer(bufnr, lines)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    return buffer.setlines(bufnr, 0, -1, lines)
end

function buffer.currentline(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    return buffer.call(bufnr, function()
        return vim.fn.getline "."
    end)
end

function buffer.tillcursor(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    local winnr = buffer.winnr(winnr)
    if not winnr then
        return
    end

    local pos = win.pos(winnr)
    return buffer.getlines(bufnr, 0, win.row)
end

function buffer.append(bufnr, lines)
    return buffer.setlines(bufnr, -1, -1, lines)
end

function buffer.prepend(bufnr, lines)
    return buffer.setlines(bufnr, 0, 0, lines)
end

function buffer.maplines(bufnr, f)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    return array.map(buffer.lines(bufnr, 0, -1), f)
end

function buffer.grep(bufnr, f)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    return array.grep(buffer.lines(bufnr, 0, -1), f)
end

function buffer.filter(bufnr, f)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    return array.filter(buffer.lines(bufnr, 0, -1), f)
end

function buffer.match(bufnr, pat)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    return array.grep(buffer.lines(bufnr, 0, -1), function(s)
        return s:match(pat)
    end)
end

function buffer.readfile(bufnr, fname)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    local s = file.read(fname)
    return buffer.setlines(bufnr, -1, s)
end

function buffer.insertfile(bufnr, fname)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    local s = file.read(fname)
    return buffer.append(bufnr, s)
end

function buffer.save(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    buffer.call(bufnr, function()
        vim.cmd "w! %:p"
    end)
    return true
end

function buffer.shell(bufnr, command)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    buffer.call(bufnr, function()
        vim.cmd(":%! " .. command)
    end)

    return buffer.lines(bufnr)
end

function buffer.name(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    return vim.api.nvim_buf_get_name(bufnr or vim.fn.bufnr())
end

function buffer.create_empty(listed, scratch)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    return vim.api.nvim_create_buf(listed, scratch)
end

function buffer.isempty(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    return #buffer.getbuffer(bufnr) == 0
end

function buffer.create(name)
    return buffer.exists(name) and buffer.bufnr(name) or buffer.bufadd(name)
end

function buffer.scratch(name, filetype)
    if not name then
        return buffer.create_empty(listed, true)
    end
    local bufnr = buffer.bufadd(name)

    if bufnr == 0 then
        return
    end

    buffer.setoption(bufnr, { buflisted = false, buftype = "nofile", filetype = filetype })

    return bufnr
end

function buffer.menu(desc, items, formatter, callback)
    validate {
        description = { is_string_or_table, desc },
        items = { is_string_or_table, items },
        callback = { "callable", callback },
        ["?formatter"] = { "callable", formatter },
    }

    if is_a.string(dict.items) then
        dict.items = vim.split(items, "\n")
    end
    if is_a.string(desc) then
        desc = vim.split(desc, "\n")
    end
    local b = buffer.scratch()
    local desc_n = #desc
    local s = array.extend(desc, items)
    local lines = copy(s)
    if formatter then
        s = array.map(s, formatter)
    end
    local _callback = callback

    callback = function()
        local idx = vim.fn.line "."
        if idx <= desc_n then
            return
        end
        _callback(lines[idx])
    end

    buffer.setbuffer(b, s)
    buffer.setopt(b, "modifiable", false)
    buffer.hook(b, "WinLeave", function()
        buffer.delete(b)
    end)
    buffer.bind(b, { noremap = true, event = "BufEnter" }, {
        "q",
        function()
            buffer.hide(b)
        end,
    }, { "<CR>", callback, "Run callback" })

    return b
end

function buffer.input(text, cb, opts)
    validate {
        text = { is_string_or_table, text },
        cb = { "callable", cb },
        ["?opts"] = { "dict", opts },
    }

    opts = opts or {}

    local split = opts.split or "s"
    local trigger = opts.keys or "gx"
    local comment = opts.comment or "#"

    if is_a(text, "string") then
        text = vim.split(text, "\n")
    end

    local buf = buffer.scratch()
    buffer.hook(buf, "WinLeave", function()
        buffer.wipeout(buf)
    end)
    buffer.setlines(buf, 0, -1, text)
    buffer.split(buf, split, { reverse = opts.reverse, resize = opts.resize })
    buffer.noremap(buf, "n", "q", function()
        buffer.hide(buf)
    end, "Close buffer")
    buffer.noremap(buf, "n", trigger, function()
        local lines = buffer.lines(buffer.bufnr(), 0, -1)
        local sanitized = {}
        local idx = 1

        array.each(lines, function(s)
            if not s:match("^" .. comment) then
                sanitized[idx] = s
                idx = idx + 1
            end
        end)

        cb(sanitized)
    end, "Execute callback")

    return buf
end

--- Get treesitter node text at position
-- @tparam number bufnr
-- @tparam number row
-- @tparam number col
-- @treturn string
function buffer.get_node_text_at_pos(bufnr, row, col)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    local node = vim.treesitter.get_node { bufnr = bufnr, pos = { row, col } }
    if not node then
        return
    end

    return table.concat(buffer.text(bufnr, node:range()), "\n")
end

function buffer.windows(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    if not buffer.exists(bufnr) then
        return
    end

    local out = vim.fn.win_findbuf(buffer.bufnr())
    if #out == 0 then
        return
    else
        return out
    end
end

function buffer.split(bufnr, direction)
    direction = direction or "s"
    local bufnr = bufnr or buffer.current()
    if not buffer.exists(bufnr) then
        return
    end

    local function cmd(s)
        local s = s .. " | b " .. bufnr
        vim.cmd(s)
    end

    if direction == "vert" or direction == "vertical" or direction == "v" then
        cmd ":vsplit"
    elseif direction == "split" or direction == "horizontal" or direction == "s" then
        cmd ":split"
    elseif direction == "botright" then
        cmd ":botright"
    elseif direction == "topleft" then
        cmd ":topleft"
    elseif direction == "aboveleft" or direction == "leftabove" then
        cmd ":aboveleft"
    elseif direction == "belowright" or direction == "rightbelow" then
        cmd ":belowright"
    elseif direction == "tabnew" or direction == "t" or direction == "tab" then
        cmd ":tabnew"
    end

    return true
end

function buffer.botright(bufnr)
    return buffer.split(bufnr, "botright")
end

function buffer.topleft(bufnr)
    return buffer.split(bufnr, "topleft")
end

function buffer.rightbelow(bufnr)
    return buffer.split(bufnr, "belowright")
end

function buffer.leftabove(bufnr)
    return buffer.split(bufnr, "aboveleft")
end

function buffer.belowright(bufnr)
    return buffer.split(bufnr, "belowright")
end

function buffer.aboveleft(bufnr)
    return buffer.split(bufnr, "aboveleft")
end

function buffer.tabnew(bufnr)
    return buffer.split(bufnr, "t")
end

function buffer.vsplit(bufnr)
    return buffer.split(bufnr, "v")
end

function floatmt:__call(bufnr, opts)
    validate {
        win_options = {
            {
                __nonexistent = true,
                ["?center"] = "array",
                ["?panel"] = "number",
                ["?dock"] = "number",
            },
            opts or {},
        },
    }

    local function from_percent(current, width, min)
        current = current or vim.fn.winwidth(0)
        width = width or 0.5

        assert(width ~= 0, "width cannot be 0")
        assert(width > 0, "width cannot be < 0")

        if width < 1 then
            required = math.floor(current * width)
        else
            return width
        end

        if min < 1 then
            min = math.floor(current * min)
        else
            min = math.floor(min)
        end

        if required < min then
            required = min
        end

        return required
    end

    bufnr = bufnr or buffer.current()
    local winnr = vim.fn.bufwinnr(bufnr)
    opts = opts or {}
    local dock = opts.dock
    local panel = opts.panel
    local center = opts.center
    local focus = opts.focus
    opts.dock = nil
    opts.panel = nil
    opts.center = nil
    opts.style = opts.style or "minimal"
    opts.border = opts.border or "single"
    local editor_size = win.vimsize()
    local current_width = win.width()
    local current_height = win.height()
    opts.width = opts.width or current_width
    opts.height = opts.height or current_height
    opts.relative = opts.relative or "editor"
    focus = focus == nil and true or focus

    if center then
        if opts.relative == "editor" then
            current_width = editor_size[1]
            current_height = editor_size[2]
        end
        local width, height = unpack(center)
        width = math.floor(from_percent(current_width, width, 10))
        height = math.floor(from_percent(current_height, height, 5))
        local col = (current_width - width) / 2
        local row = (current_height - height) / 2
        opts.width = width
        opts.height = height
        opts.col = math.floor(col)
        opts.row = math.floor(row)
    elseif panel then
        if opts.relative == "editor" then
            current_width = editor_size[1]
            current_height = editor_size[2]
        end
        opts.row = 0
        opts.col = 1
        opts.width = from_percent(current_width, panel, 5)
        opts.height = current_height
        if reverse then
            opts.col = current_width - opts.width
        end
    elseif dock then
        if opts.relative == "editor" then
            current_width = editor_size[1]
            current_height = editor_size[2]
        end
        opts.col = 0
        opts.row = opts.height - dock
        opts.height = from_percent(current_height, dock, 5)
        opts.width = current_width > 5 and current_width - 2 or current_width
        if reverse then
            opts.row = opts.height
        end
    end

    local winid = vim.api.nvim_open_win(bufnr, focus, opts)
    if winid == 0 then
        return false
    end

    return bufnr
end

function float.setconfig(winnr, config)
    config = config or {}
    local ok, msg = pcall(vim.api.nvim_win_set_config, win.id(winnr), config)
    if not ok then
        return
    end

    return true
end

function float.getconfig(winnr)
    if not win.exists(winnr) then
        return
    end

    local ok, msg = pcall(vim.api.nvim_win_get_config, win.id(winnr))
    if not ok then
        return
    end

    return ok
end

--------------------------------------------------
--
local copy_methods = {
    "scroll",
    "height",
    "width",
    "size",
    "restoreview",
    "restorecmd",
    "saveview",
    "currentline",
    "virtualcol",
    "setheight",
    "setwidth",
    "close",
    "hide",
    "range",
    "rangetext",
    "cursorpos",
    "tabnew",
    "row",
    "col",
    "move_statusline",
    "move_separator",
    "screenpos",
    "pos",
}

array.each(copy_methods, function(name)
    buffer[name] = function(bufnr, ...)
        bufnr = bufnr or buffer.bufnr()
        if not bufnr then
            return
        end

        local winnr = buffer.winnr(bufnr)
        if not winnr then
            return
        end

        return win[name](winnr, ...)
    end
end)

return buffer
