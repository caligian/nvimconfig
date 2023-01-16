local kbd = user.builtin.kbd
kbd.autocmds = {}

function kbd.map(...)
    for _, form in ipairs({...}) do
        local mode, lhs, rhs, opts = unpack(form)
        opts = opts or {}
        local autocmd_opts = {}
        local kbd_opts = {}
        local event, pattern = opts.event, opts.pattern
        mode = ensure_list(mode)
        local buffer = opts.buffer

        for key, value in pairs(opts) do
            if key == 'event' or key == 'pattern' or key == 'once' or key == 'nested' then
                autocmd_opts[key] = value
            else
                kbd_opts[key] = value
            end
        end

        if event or pattern then
            event = event or 'BufEnter'
            local id = vim.api.nvim_create_autocmd(event, {
                pattern = pattern,
                nested = autocmd_opts.nested,
                once = autocmd_opts.once,
                callback = function ()
                    kbd_opts.buffer = vim.fn.bufnr()
                    vim.keymap.set(mode, lhs, rhs, kbd_opts)
                end
            })

            kbd.autocmds[id] = {
                autocmd_id = id,
                mode = mode,
                lhs = lhs,
                rhs = rhs,
                event = event,
                pattern = pattern,
                once = autocmd_opts.once,
                nested = autocmd_opts.nested,
                opts = kbd_opts,
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
                once = autocmd_opts.once,
                nested = autocmd_opts.nested,
                opts = kbd_opts,
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

function kbd.noremap_with_options(opts, ...)
    opts = opts or {}
    for _, form in ipairs({...}) do
        local options = extend('force', form[4] or {}, opts)
        form[4] = options
        kbd.noremap(form)
    end
end

function kbd.map_with_options(opts, ...)
    opts = opts or {}
    for _, form in ipairs({...}) do
        local options = extend('force', form[4] or {}, opts)
        form[4] = options
        kbd.map(form)
    end
end
