local _ = telescope.load()
local mod = {}

function mod.bwipeout(bufnr)
    local sel = _:get_selected(bufnr, true)

    array.each(sel, function (x)
        print("Wiping out buffer " .. x.bufnr)
        vim.cmd("bwipeout! " .. x.bufnr)
    end)
end

function mod.nomodified(bufnr)
    local sels = _:get_selected(bufnr, true)

    array.each(sels, function (sel)
        print("Setting buffer status to nomodified: " .. vim.fn.bufname(sel.bufnr))
        vim.api.nvim_buf_call(sel.bufnr, function() vim.cmd "set nomodified" end)
    end)
end

function mod.save(bufnr)
    local sels = _:get_selected(bufnr, true)
    array.each(sels, function ()
        print("Saving buffer " .. sel.bufnr)
        local name = vim.fn.bufname(sel.bufnr)
        vim.cmd("w " .. name)
    end)
end

function mod.readonly(bufnr)
    local sels = _:get_selected(bufnr, true)
    array.each(sels, function (sel)
        print("Setting buffer to readonly: " .. vim.fn.bufname(sel.bufnr))
        vim.api.nvim_buf_call(sel.bufnr, function() vim.cmd "set nomodifiable" end)
    end)
end

return mod
