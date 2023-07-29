autocmd.map("TextYankPost", {
    name = "highlight_on_yank",
    pattern = "*",
    callback = function()
        vim.highlight.on_yank { timeout = 100 }
    end,
})

autocmd.map("BufAdd", {
    name = "textwidth_colorcolumn",
    pattern = "*",
    callback = function()
        win.set_option(vim.fn.bufnr(), "colorcolumn", "+2")
    end,
})

autocmd.map('BufAdd', {
	pattern = '*',
	callback = function (opts)
        local bufnr = opts.buf
        local bufname = buffer.name(bufnr)
        local function map_quit()
            buffer.map(bufnr, 'ni', 'q', '<cmd>hide<CR>')
        end

        dict.each(user.temp_buffer_patterns, function (_, pat)
            if is_callable(pat) then
                if pat(bufname) then
                    map_quit()
                end
            elseif is_array_of(pat, 'string') then
                for i = 1, #pat do
                    if bufname:match(pat[i]) then
                        map_quit()
                        break
                    end
                end
            elseif is_string(pat) then
                if bufname:match(pat) then
                    map_quit()
                end
            elseif is_table(pat) and pat.ft then
                if buffer.option(bufnr, 'filetype') == pat.ft then
                    map_quit()
                end
            end
        end)
    end,
})

if req2path "user.autocmds" then
    require "user.autocmds"
end
