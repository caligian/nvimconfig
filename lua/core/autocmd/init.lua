user.autocmd = {}
local au = user.autocmd
builtin.get(au, 'ids', true)
builtin.get(au, 'groups', true)

function au.create_augroup(group, clear)
    local id = vim.api.nvim_create_augroup(group, { clear = clear })
    au.groups[id] = {}
    au.groups[group] = au.groups[id]
end

function au.create(event, pattern, callback, opts)
    opts = opts or {}
    opts.pattern = pattern
    opts.callback = callback
    local name = builtin.deep_copy(opts.name)
    local augroup_id = nil

    assert(name, "No autocmd name provided")

    if opts.group then
        augroup_id = au.create_augroup(opts.group, opts.clear_group)
    end

    opts.name = nil
    opts.clear_group = nil
    local id = vim.api.nvim_create_autocmd(event, opts)
    local new = {
        name = name,
        id = id,
        event = event,
        pattern = pattern,
        group = opts.group,
        group_id = augroup_id,
    }
    au.ids[id] = new
    au.ids[name] = new

    if opts.group then
        au.groups[opts.group][name] = new
    end

    return new
end

function au.delete(id)
    return vim.api.nvim_del_autocmd(au.ids[id].id)
end

function au.delete_augroup(id)
    return vim.api.nvim_del_autocmd(au.ids[id].group_id)
end
