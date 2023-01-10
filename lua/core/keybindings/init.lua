user.builtin.keybindings = {}
local kbd = user.builtin.keybindings
kbd.autocmds = {}

function kbd.map(...)
    for _, form in ipairs({...}) do
        local mode, lhs, rhs, opts = unpack(form)
        opts = opts or {}
        local event, pattern = vim.deepcopy(opts.event), vim.deepcopy(opts.pattern)
        if type(mode) ~= 'table' then
            mode = {mode}
        end
        local buffer = opts.buffer

        if event or pattern then
            event = event or 'BufEnter'
            local id = vim.api.nvim_create_autocmd(event, {
                pattern = pattern,
                nested = opts.nested,
                once = opts.once,
                callback = function ()
                    opts.event = nil
                    opts.pattern = nil
                    opts.once = nil
                    opts.nested = nil
                    vim.keymap.set(mode, lhs, rhs, opts)
                end
            })

            kbd.autocmds[id] = {
                autocmd_id = id,
                mode = mode,
                lhs = lhs,
                rhs = rhs,
                event = event,
                pattern = pattern,
                once = opts.once,
                nested = opts.nested,
                opts = opts,
                disable = function ()
                    for _, m in ipairs(mode) do
                        vim.api.nvim_del_keymap(m, lhs)
                    end
                    vim.api.nvim_del_autocmd(id)
                end,
            }

            for _, m in ipairs(mode) do
                kbd[m] = kbd[m] or {}
                kbd[m][id] = kbd.autocmds[id]
            end
        else
            vim.keymap.set(mode, lhs, rhs, opts)
            local k = {
                mode = mode,
                lhs = lhs,
                rhs = rhs,
                event = event,
                pattern = pattern,
                once = opts.once,
                nested = opts.nested,
                opts = opts,
                disable = function ()
                    for _, m in ipairs(mode) do
                        if buffer then
                            vim.api.nvim_buf_del_keymap(buffer, m, lhs)
                        else
                            vim.api.nvim_del_keymap(m, lhs)
                        end
                    end
                end
            }

            for _, m in ipairs(mode) do
                kbd[m] = kbd[m] or {}
                kbd[m][lhs] = k
            end
        end
    end
end

function kbd.noremap(...)
    for _, form in ipairs({...}) do
        local opts = form[4] or {}
        opts.noremap = true
        form[4] = opts
        kbd.map(form)
    end
end

function kbd.unmap(mode, lhs)
    local k = kbd[mode][lhs]
    if not k.disabled then
        k.disable()
        k.disabled = true
    end
end
