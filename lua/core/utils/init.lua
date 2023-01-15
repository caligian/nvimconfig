flatten = vim.tbl_flatten
substr = string.sub
sprintf = string.format
filter = vim.tbl_filter
extend = vim.tbl_extend
deep_copy = vim.deepcopy
is_empty = vim.tbl_isempty
is_list = vim.tbl_islist
keys = vim.tbl_keys
values = vim.tbl_values
map = vim.tbl_map
trim = vim.trim
validate_params = vim.validate
ui_select = vim.ui.select

function each(f, t)
    for _, value in ipairs(t) do
        f(value)
    end
end

function each_with_index(f, t)
    for idx, value in ipairs(t) do
        f(idx, value)
    end
end

function map_with_index(f, t)
    local out = {}
    for index, value in ipairs(t) do
        out[index] = f(index, value)
    end

    return out
end

function inspect(...)
    local final_s = ''

    for _, obj in ipairs({ ... }) do
        final_s = final_s .. vim.inspect(obj) .. "\n\n"
    end

    vim.api.nvim_echo({ { final_s } }, false, {})
end

function ensure_list(e, force)
    if force then
        return { e }
    elseif type(a) ~= 'table' then
        return { e }
    else
        return e
    end
end

function is_type(e, t)
    return type(e) == t
end

function assert_type(e, t)
    local out = is_type(e)
    assert(out)

    return out
end

function append(t, ...)
    local idx = 1
    for _, value in ipairs({ ... }) do
        t[idx] = value
        idx = idx + 1
    end

    return t
end

function append_at_index(t, idx, ...)
    for _, value in ipairs({ ... }) do
        table.insert(t, idx, value)
    end

    return t
end

function shift(t, times)
    local new = {}
    local idx = 1
    for i = times, #t do
        new[idx] = t[i]
        idx = idx + 1
    end

    return new
end

function unshift(t, ...)
    local new = { ... }
    local idx = 1
    for _, value in ipairs(t) do
        new[idx] = value
        idx = idx + 1
    end

    return new
end

-- For multiple patterns, OR matching will be used
function match(s, ...)
    for _, value in ipairs({ ... }) do
        local m = s:match(value)
        if m then
            return m
        end
    end
end

function add_global(varname, value, overwrite)
    if overwrite or (not _G[varname]) then
        _G[varname] = value
    end
end

function butlast(t)
    local new = {}

    for i = 1, #t - 1 do
        new[i] = t[i]
    end

    return new
end

function last(t, n)
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

function first(t, n)
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

function rest(t)
    local new = {}
    local len = #t
    local idx = 1

    for i = 2, len do
        new[idx] = t[i]
        idx = idx + 1
    end

    return new
end

function update(tbl, keys, value)
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

function rpartial(f, ...)
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

function partial(f, ...)
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

function get(tbl, ks, create_path)
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

function merge(a, b)
    local at = a
    local bt = b

    for key, value in pairs(bt) do
        local av = at[key]
        local bv = value

        if av == nil then
            at[key] = bv
        end

        if type(bv) == 'table' and type(av) == 'table' then
            merge(at[key], value)
        else
            at[key] = value
        end
    end

    return a
end

function merge_keepleft(a, b)
    local at = a
    local bt = b

    for key, value in pairs(bt) do
        local av = at[key]
        local bv = value

        if av == nil then
            at[key] = bv
        end

        if type(bv) == 'table' and type(av) == 'table' then
            merge_keepleft(at[key], value)
        elseif value ~= nil then
            at[key] = value
        end
    end

    return a
end

function printf(...)
    print(string.format(...))
end

function with_open(fname, mode, callback)
    local fh = io.open(fname, mode)
    local out = nil
    if fh then
        out = callback(fh)
        fh:close()
    end

    return out
end

function slice(t, from, till)
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
