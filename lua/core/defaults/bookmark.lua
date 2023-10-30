Bookmark.mappings =  {
    opts = {
        noremap = true,
    },
    add_buffer = {
        "gba",
        function()
            local count = vim.v.count
            local bufname = buffer.name()

            if count == 0 then
                Bookmark.add_and_save(bufname, win.pos().row)
            else
                Bookmark.add_and_save(bufname, count)
            end
        end,
        { desc = "add current buffer" },
    },
    open_dwim_picker = {
        "g<space>",
        function ()
            Bookmark.run_dwim_picker()
        end,
        {desc = 'dwim picker'}
    },
    open_picker = {
        "g.",
        function()
            Bookmark.run_picker()
        end,
        { desc = "run picker" },
    },
}

return function ()
    kbd.map_group('Bookmark', Bookmark.mappings)
end
