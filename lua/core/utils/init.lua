builtin = {globals = {}}
builtin.flatten = vim.tbl_flatten
builtin.substr = string.sub
builtin.sprintf = string.format
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
    local idx = #tbl
    for _, t in ipairs({...}) do
        if type(t) == 'table' then
            for _, value in ipairs(t) do
                tbl[idx+1] = value
            end
        else
            tbl[idx+1] = t
        end
        idx = idx + 1
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
    local idx = 1
    for _, value in ipairs({ ... }) do
        t[idx] = value
        idx = idx + 1
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
    local new = {}
    local idx = 1
    for i = times, #t do
        new[idx] = t[i]
        idx = idx + 1
    end

    return new
end

function builtin.unshift(t, ...)
    local new = { ... }
    local idx = 1
    for _, value in ipairs(t) do
        new[idx] = value
        idx = idx + 1
    end

    return new
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

    return function ()
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
    assert(till > from, 'End index cannot be bigger than start index')

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

    return builtin.index(keymaps, lhs, function (t, item)
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
        if types.is_type(opts.insert, 'table') then
            opts.insert = table.concat(opts.insert, opts.sep or "\n")
        end
    end

    vim.api.nvim_buf_call(bufnr, function ()
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
            vim.keymap.set('n', opts.keys, function ()
                opts.callback(vim.api.nvim_buf_get_lines(0, 0, -1, false))
            end, {buffer=bufnr})
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
    return table.concat({...}, '/')
end

function builtin.basename(s)
    s = vim.split(s, '/')
    return s[#s]
end

function builtin.get_visual_range(bufnr)
    bufnr = bufnr or 0
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    return vim.api.nvim_buf_get_text(bufnr, start_pos[2]-1, start_pos[3]-1, end_pos[2]-1, end_pos[3], {})
end

function builtin.add_package_cpath(...)
    for _, value in ipairs({...}) do
        package.cpath = package.cpath .. ';' .. value
    end
end

function builtin.add_package_path(...)
    for _, value in ipairs({...}) do
        package.path = package.path .. ';' .. value
    end
end

function builtin.require_rock(...)
    local missing_rocks = {}
    for _, rock in ipairs({...}) do
        if not pcall(require, rock) then
            missing_rocks[#missing_rocks+1] = rock
        end
    end

    return missing_rocks
end

function builtin.nvim_err(...)
    for _, s in ipairs({...}) do
       vim.api.nvim_err_writeln(s)
    end
end

function builtin.is_a(e, c)
	if type(c) == 'string' then
		return type(e) == c
	elseif type(e) == 'table' then
		if e.is_a and e.is_a(c) then
			return true
		else
			return 'table' == c
		end
	end
end
