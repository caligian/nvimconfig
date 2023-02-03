local fennel = require 'fennel'

if not builtin then builtin = {} end
if not builtin.globals then builtin.globals = {} end
if not builtin.logs then builtin.logs = {} end
builtin.stdpath = vim.fn.stdpath
builtin.flatten = vim.tbl_flatten
builtin.substr = string.sub
builtin.sprintf = string.format
sprintf = builtin.sprintf
builtin.filter = vim.tbl_filter
builtin.deep_copy = vim.deepcopy
builtin.is_empty = vim.tbl_isempty
builtin.is_list = vim.tbl_islist
builtin.keys = vim.tbl_keys
builtin.values = vim.tbl_values
builtin.map = vim.tbl_map
builtin.trim = vim.trim
builtin.validate = vim.validate

function builtin.extend(tbl, ...)
    local l = #tbl
    for i, t in ipairs({ ... }) do
        if type(t) == 'table' then
            for j, value in ipairs(t) do
                tbl[l + j] = value
            end
        else
            tbl[l + i] = t
        end
    end

    return tbl
end

function builtin.each(f, t)
    for _, value in ipairs(t) do
        f(value)
    end
end

function builtin.each_with_index(f, t)
    for idx, value in ipairs(t) do
        f(idx, value)
    end
end

function builtin.map_with_index(f, t)
    local out = {}
    for index, value in ipairs(t) do
        out[index] = f(index, value)
    end

    return out
end

function builtin.inspect(...)
    local final_s = ''

    for _, obj in ipairs({ ... }) do
        final_s = final_s .. vim.inspect(obj) .. "\n\n"
    end

    vim.api.nvim_echo({ { final_s } }, false, {})
end

inspect = builtin.inspect

function builtin.ensure_list(e, force)
    if force then
        return { e }
    elseif type(e) ~= 'table' then
        return { e }
    else
        return e
    end
end

function builtin.is_type(e, t)
    return type(e) == t
end

function builtin.assert_type(e, t)
    local out = builtin.is_type(e)
    assert(out)

    return out
end

function builtin.append(t, ...)
    local idx = #t
    for i, value in ipairs({ ... }) do
        t[idx + i] = value
    end

    return t
end

function builtin.append_at_index(t, idx, ...)
    for _, value in ipairs({ ... }) do
        table.insert(t, idx, value)
    end

    return t
end

function builtin.shift(t, times)
    local l = #t
    for i = 1, times do
        if i > t then
            return t
        end
        table.remove(t, 1)
    end

    return t
end

function builtin.unshift(t, ...)
    for _, value in ipairs({ ... }) do
        table.insert(t, 1, value)
    end

    return t
end

-- For multiple patterns, OR matching will be used
function builtin.match(s, ...)
    for _, value in ipairs({ ... }) do
        local m = s:match(value)
        if m then
            return m
        end
    end
end

-- If varname in [varname] = var is prefixed with '!' then it will be overwritten
function builtin.global(vars)
    for var, value in pairs(vars) do
        if var:match('^!') then
            var = var:gsub('^!', '')
            _G[var] = value
        elseif _G[var] == nil then
            _G[var] = value
        end
        builtin.globals[var] = value
    end
end

function builtin.range(from, till, step)
    local index = from
    step = step or 1

    return function()
        index = index + step
        if index <= till then
            return index
        end
    end
end

function builtin.butlast(t)
    local new = {}

    for i = 1, #t - 1 do
        new[i] = t[i]
    end

    return new
end

function builtin.last(t, n)
    if n then
        local len = #t
        local new = {}
        local idx = 1
        for i = len - n + 1, len do
            new[idx] = t[i]
            idx = idx + 1
        end

        return new
    else
        return t[#t]
    end
end

function builtin.first(t, n)
    if n then
        local new = {}
        for i = 1, n do
            new[i] = t[i]
        end

        return new
    else
        return t[1]
    end
end

function builtin.rest(t)
    local new = {}
    local len = #t
    local idx = 1

    for i = 2, len do
        new[idx] = t[i]
        idx = idx + 1
    end

    return new
end

function builtin.update(tbl, keys, value)
    local len_ks = #keys
    local t = tbl

    for idx, k in ipairs(keys) do
        local v = t[k]

        if idx == len_ks then
            t[k] = value
            return value, t, tbl
        elseif type(v) == 'table' then
            t = t[k]
        else
            return
        end
    end
end

function builtin.rpartial(f, ...)
    local outer = { ... }
    return function(...)
        local inner = { ... }
        local len = #outer
        for idx, a in ipairs(outer) do
            inner[len + idx] = a
        end

        return f(unpack(inner))
    end
end

function builtin.partial(f, ...)
    local outer = { ... }
    return function(...)
        local inner = { ... }
        local len = #outer
        for idx, a in ipairs(inner) do
            outer[len + idx] = a
        end

        return f(unpack(outer))
    end
end

function builtin.get(tbl, ks, create_path)
    if type(ks) ~= 'table' then
        ks = { ks }
    end

    local len_ks = #ks
    local t = tbl
    local v = nil
    for index, k in ipairs(ks) do
        v = t[k]

        if v == nil then
            if create_path then
                t[k] = {}
                t = t[k]
            else
                return
            end
        elseif type(v) == 'table' then
            t = t[k]
        elseif len_ks ~= index then
            return
        end
    end

    return v, t, tbl
end

function builtin.merge(a, b)
    local at = a
    local bt = b

    for key, value in pairs(bt) do
        local av = at[key]
        local bv = value

        if av == nil then
            at[key] = bv
        end

        if type(bv) == 'table' and type(av) == 'table' then
            builtin.merge(at[key], value)
        else
            at[key] = value
        end
    end

    return a
end

function builtin.merge_keepleft(a, b)
    local at = a
    local bt = b

    for key, value in pairs(bt) do
        local av = at[key]
        local bv = value

        if av == nil then
            at[key] = bv
        end

        if type(bv) == 'table' and type(av) == 'table' then
            builtin.merge_keepleft(at[key], value)
        elseif value ~= nil then
            at[key] = value
        end
    end

    return a
end

function builtin.printf(...)
    print(string.format(...))
end

function builtin.with_open(fname, mode, callback)
    local fh = io.open(fname, mode)
    local out = nil
    if fh then
        out = callback(fh)
        fh:close()
    end

    return out
end

function builtin.slice(t, from, till)
    till = till or #t
    assert(till >= from, 'Start index cannot be bigger than end index')

    local out = {}
    local idx = 1
    for i = from, till do
        out[idx] = t[i]
        idx = idx + 1
    end

    return out
end

function builtin.index(t, item, test)
    for key, v in pairs(t) do
        if test then
            if test(v, item) then
                return key
            end
        elseif item == v then
            return key
        end
    end
end

function builtin.buffer_has_keymap(bufnr, mode, lhs)
    bufnr = bufnr or 0
    local keymaps = vim.api.nvim_buf_get_keymap(bufnr, mode)
    lhs = lhs:gsub('<leader>', vim.g.mapleader)
    lhs = lhs:gsub('<localleader>', vim.g.maplocalleader)

    return builtin.index(keymaps, lhs, function(t, item)
        return t.lhs == item
    end)
end

function builtin.open_scratch_buffer(opts)
    opts = opts or {}
    opts.name = opts.name or 'scratch_buffer'
    opts.ft = opts.ft or vim.bo.filetype or 'lua'
    opts.split = opts.split or 's'
    local bufnr = vim.fn.bufnr(opts.name)

    if vim.fn.bufexists(opts.name) == 0 then
        bufnr = vim.fn.bufadd(opts.name)
    end

    if opts.insert then
        if types.is_type(opts.insert, 'string') then
            opts.insert = vim.split(opts.insert, opts.sep or "\n")
        end
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, opts.insert)
    end

    vim.api.nvim_buf_call(bufnr, function()
        vim.cmd('set buftype=nofile')
        vim.cmd('set nobuflisted')
        vim.cmd('set ft=' .. opts.ft)
    end)

    if opts.callback then
        opts.keys = opts.keys or '<C-c><C-c>'
        vim.api.nvim_buf_set_var(bufnr, 'callback_keymap', opts.keys)

        local ok, _ = pcall(vim.api.nvim_buf_get_var, bufnr, 'is_keymap_set')
        if not ok or opts.overwrite then
            vim.api.nvim_buf_set_var(bufnr, 'is_keymap_set', true)
            vim.keymap.set('n', opts.keys, function()
                opts.callback(vim.api.nvim_buf_get_lines(0, 0, -1, false))
            end, { buffer = bufnr })
        end
    end

    if opts.switch then
        vim.cmd('b ' .. opts.name)
    elseif opts.split == 's' then
        vim.cmd('split | wincmd j | b ' .. opts.name)
    elseif opts.split == 'v' then
        vim.cmd('vsplit | wincmd l | b ' .. opts.name)
    else
        vim.cmd('tabnew ' .. opts.name)
    end
end

function builtin.join_path(...)
    return table.concat({ ... }, '/')
end

function builtin.basename(s)
    s = vim.split(s, '/')
    return s[#s]
end

function builtin.get_visual_range(bufnr)
    return vim.api.nvim_buf_call(bufnr or vim.fn.bufnr(), function()
        local _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
        local _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))
        if csrow < cerow or (csrow == cerow and cscol <= cecol) then
            return vim.api.nvim_buf_get_text(0, csrow - 1, cscol - 1, cerow - 1, cecol, {})
        else
            return vim.api.nvim_buf_get_text(0, csrow - 1, cscol - 1, cerow - 1, cscol, {})
        end
    end)
end

function builtin.add_package_cpath(...)
    for _, value in ipairs({ ... }) do
        package.cpath = package.cpath .. ';' .. value
    end
end

function builtin.add_package_path(...)
    for _, value in ipairs({ ... }) do
        package.path = package.path .. ';' .. value
    end
end

function builtin.require_rock(...)
    local missing_rocks = {}
    for _, rock in ipairs({ ... }) do
        if not pcall(require, rock) then
            missing_rocks[#missing_rocks + 1] = rock
        end
    end

    return missing_rocks
end

function builtin.nvim_err(...)
    for _, s in ipairs({ ... }) do
        vim.api.nvim_err_writeln(s)
    end
end

function builtin.is_a(e, c)
    if type(c) == 'string' then
        return type(e) == c
    elseif type(e) == 'table' then
        if e.is_a and e:is_a(c) then
            return true
        else
            return 'table' == c
        end
    end
end

-- If multiple keys are supplied, the table is going to be assumed to be nested
function builtin.has_key(tbl, ...)
    return (builtin.get(tbl, { ... }))
end

function builtin.make_tpath(tbl, ks)
    return builtin.get(tbl, ks, true)
end

-- Compiles fennel files to lua
-- Saves them in ~/.config/nvim/lua/compiled
function builtin.compile(src, dest)
    local s = file.read(p)
    local s = fennel.compileString(s)
    file.write(dest, s)
end

function builtin.compile_buffer(bufnr, eval)
    bufnr = bufnr or vim.fn.bufnr()
    local bufname = vim.api.nvim_buf_call(bufnr, function()
        return vim.fn.expand('%:p')
    end)

    if not bufname:match('fnl$') then
        error(sprintf('Buffer %s is not a fennel buffer', bufname))
    end

    local home = path.join(os.getenv('HOME'), '.nvim', 'lua', 'user')
    local stdpath = path.join(vim.fn.stdpath('config'), 'lua')
    local is_user = bufname:match(home)
    local is_sys = bufname:match(stdpath)
    local dest = ''

    assert(is_user or is_sys, 'Only nvim configuration fennel buffers can be compiled')

    if is_user then
        dest = bufname:gsub(home, '')
    else
        dest = bufname:gsub(stdpath, '')
    end
    dest = dest:gsub('fnl$', 'lua')
    dest = 'compiled' .. dest

    if is_user then
        dest = home .. '/' .. dest
    else
        dest = stdpath .. '/' .. dest
    end

    local s = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    s = table.concat(s, "\n\r")

    local parent = path.dirname(dest)
    if not path.exists(parent) then
        dir.makepath(parent)
    end
    file.write(dest, fennel.compileString(s))

    if eval then
        fennel.eval(s)
    end
end

function builtin.pcall(f, ...)
    local ok, out = pcall(f, ...)
    if ok then
        return {
            error = false,
            success = true,
            out = out,
        }
    else
        return {
            error = ok,
            success = false,
        }
    end
end

function builtin.makepath(t, ...)
    return builtin.get(t, { ... }, true)
end

function builtin.require(req, do_assert)
    local ok, out = pcall(require, req)

    if not ok then
        builtin.makepath(builtin, 'logs')
        builtin.append(builtin.logs, out)

        if do_assert then
            error(out)
        end
    else
        return out
    end
end

return builtin
