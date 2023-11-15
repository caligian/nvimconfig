-- Only works for toggleable options
local function _toggle_option(option)
    local bufnr = vim.fn.bufnr()
    local winid = vim.fn.bufwinid(bufnr)
    local ok, out = pcall(vim.api.nvim_buf_get_option, bufnr, option)

    if ok then
        vim.api.nvim_buf_set_option(bufnr, option, not out)
    end

    if not ok then
        ok, out = pcall(vim.api.nvim_win_get_option, winid, option)
        if ok then
            vim.api.nvim_win_set_option(winid, option, not out)
        end
    end
end

local function close_other_windows()
    local current_winid = win.current_id()
    local current_tab = vim.api.nvim_get_current_tabpage()
    local wins = vim.api.nvim_tabpage_list_wins(current_tab)

    each(wins, function(winid)
        if winid == current_winid then
            return
        else
            win.call(win.id2nr(winid), function()
                vim.cmd ":hide"
            end)
        end
    end)
end

user.mappings = user.mappings or {}

merge(user.mappings, {
    opts = {
        noremap = true,
        leader = true,
    },

    netrw = {
        inherit = true,
        netrw = { "|", ":Lexplore <bar> vert resize 40<CR>", "Open netrw" },
        netrw_quickmap1 = {
            "g?",
            ":h netrw-quickmap<CR>",
            { event = "FileType", pattern = "netrw", desc = "Help" },
        },
    },

    misc = {
        noh = {
            "n",
            "\\\\",
            ":noh<CR>",
            { desc = "No highlight", noremap = true },
        },
        term_normal_mode = {
            "t",
            "<esc>",
            "<C-\\><C-n>",
            { desc = "Terminal to normal mode" },
        },
    },

    ui = {
        inherit = true,
        zenmode = {
            "oz",
            ":ToggleZenMode<CR>",
            "Toggle Zen mode",
        },
    },

    buffers = {
        inherit = true,
        format = {
            "bf",
            function()
                local bufname = buffer.name()
                local ft = vim.bo.filetype

                if #ft == 0 or #bufname == 0 then
                    return
                end

                if not filetype.filetypes[ft] then
                    pp(sprintf("no formatter defined for " .. ft))
                else
                    local x = filetype.filetypes[ft]
                    filetype.format_buffer(x)
                end
            end,
            { desc = "format buffer" },
        },
        format_dir = {
            "bF",
            function()
                local bufname = buffer.name()
                local ft = vim.bo.filetype

                if #ft == 0 or #bufname == 0 then
                    return
                end

                if not filetype.filetypes[ft] then
                    pp(sprintf("no formatter defined for " .. ft))
                else
                    local x = filetype.filetypes[ft]
                    filetype.format_buffer(x)
                end
            end,
            { desc = "format current directory" },
        },
        save_bookmark = {
            "fb",
            "mA",
            { desc = "Bookmark current file at pos" },
        },
        open_doom_config = {
            "fP",
            ":chdir ~/.config/nvim <bar> e .<CR>",
            { desc = "Open framework config" },
        },
        open_user_config = {
            "fp",
            ":chdir ~/.nvim <bar> e .<CR>",
            { desc = "Open user config" },
        },
        reload = { "be", ":e!<CR>", { desc = "Reload buffer" } },
        save = { "fs", ":w! %<CR>", { desc = "Save buffer" } },
        hide = { "bk", ":hide<CR>", { desc = "Hide buffer" } },
        wipeout = { "bq", ":bwipeout! %<CR>", { desc = "Wipeout buffer" } },
        save_and_hide = {
            "bK",
            ":w! <bar> hide<CR>",
            { desc = "Save and hide buffer" },
        },
        previous = { "bp", ":bprev<CR>", { desc = "Previous buffer" } },
        next = { "bn", ":bnext<CR>", { desc = "Next buffer" } },
        first = { "b0", ":bfirst<CR>", { desc = "First buffer" } },
        last = { "b$", ":blast<CR>", { desc = "Last buffer" } },
        source = {
            "fv",
            ":w! % <bar> :source %<CR>",
            {
                event = "BufEnter",
                pattern = { "*.vim", "*.lua" },
                desc = "Source vim or lua buffer",
            },
        },
    },

    lua_eval = {
        inherit = true,
        line = {
            "ee",
            "<cmd>NvimEvalLine<CR>",
            { desc = "Lua source line", name = "eval line" },
        },
        buffer = {
            "eb",
            "<cmd>NvimEvalBuffer<CR>",
            { desc = "Lua source buffer", name = "source_buffer" },
        },
        till_cursor = {
            "e.",
            "<cmd>NvimEvalTillCursor<CR>",
            { desc = "Lua source till point", name = "source_till_point" },
        },
        region = {
            "ee",
            "<esc>:NvimEvalRegion<CR>",
            { desc = "Lua source range", mode = "v", name = "Lua source range" },
        },
    },

    scratch = {
        inherit = true,
        split = { ",", ":OpenScratch<CR>" },
        float = { "F", ":OpenScratchFloat<CR>" },
        vsplit = { ";", ":OpenScratchVertically<CR>" },
    },

    tabs = {
        inherit = true,
        new = { "tt", ":tabnew<CR>", { desc = "New tab" } },
        hide = { "tk", ":tabclose<CR>", { desc = "Close tab" } },
        next = { "tn", ":tabnext<CR>", { desc = "Next tab" } },
        previous = { "tp", ":tabprev<CR>", { desc = "Previous tab" } },
    },

    help = {
        inherit = true,
    },

    quit = {
        inherit = true,
        quit = { "qa", ":qa<CR>", ":qall" },
        force_quit = { "qq", ":qa!<CR>", ":qall!" },
        save_and_quite = { "qx", ":xa<CR>", ":xa" },
    },

    options = {
        inherit = true,
        wrap = { "ot", partial(_toggle_option, "textwrap"), "Toggle wrapping" },
        readonly = { "or", partial(_toggle_option, "readonly"), "Toggle readonly" },
        cursorline = { "oc", partial(_toggle_option, "cursorline"), "Toggle cursorline" },
        buflisted = { "ol", partial(_toggle_option, "buflisted"), "Toggle buflisted" },
        backup = { "ob", partial(_toggle_option, "backup"), "Toggle backup" },
        expandtab = { "oe", partial(_toggle_option, "expandtab"), "Toggle expandtab" },
        smartindent = { "os", partial(_toggle_option, "smartindent"), "Toggle smartindent" },
        modified = { "o!", partial(_toggle_option, "modified"), "Toggle modified status" },
        ruler = { "ou", partial(_toggle_option, "ruler"), "Toggle ruler" },
        modifiable = { "om", partial(_toggle_option, "modifiable"), "Toggle modifiable" },
    },

    windows = {
        inherit = true,
        left = { "wh", "<C-w>h", "Left win" },
        hide_others = { "wo", close_other_windows, "Hide other wins" },
        max_height = { "w_", "<C-w>_", "Max out height" },
        max_width = { "w|", "<C-w>|", "Max out width" },
        down = { "wj", "<C-w>j", "Down win" },
        up = { "wk", "<C-w>k", "Up win" },
        right = { "wl", "<C-w>l", "Right win" },
        inc_height = { "w+", "<C-w>+", "Increase height" },
        dec_height = { "w-", "<C-w>-", "Decrease height" },
        equalize = { "w=", "<C-w>=", "Equalize height and width" },
        inc_width = { "w>", "<C-w>>", "Increase width" },
        dec_width = { "w<", "<C-w><", "Decrease width" },
        split = { "ws", "<C-w>s", "Split win" },
        vspilt = { "wv", "<C-w>v", "Vsplit win" },
        tabnew = { "wt", "<C-w>T", "Tabnew win" },
        other = { "ww", "<C-w>w", "Other win" },
        swap = { "wx", "<C-w>x", "Swap win" },
    },

    editor = {
        inherit = true,
        insert_separator = {
            "#",
            function()
                local tw = vim.bo.textwidth
                local comment = split(vim.bo.commentstring or "#", " ")[1]
                if not comment then
                    return
                end

                local l = #comment
                tw = tw == 0 and 50 or tw

                if l > 1 then
                    comment = string.rep(comment, math.floor(tw / l))
                else
                    comment = string.rep(comment, tw)
                end

                vim.api.nvim_put({ comment }, "l", true, true)
            end,
            "Add separator line",
        },
    },

    qflist = {
        inherit = true,
        open = { "cq", ":botright copen<CR>", "open qflist" },
        close = { "ck", ":cclose<CR>", "close qflist" },
    },

    compile = {
        inherit = true,
        compile = {
            "cc",
            partial(filetype.compile_buffer),
            "compile current buffer",
        },
        test = {
            "ct",
            function()
                filetype.compile_buffer(buffer.current(), "test")
            end,
            "test current buffer",
        },
        build = {
            "cb",
            function()
                filetype.compile_buffer(buffer.current(), "build")
            end,
            "build current buffer",
        },
        run = {
            "cr",
            function()
                local cmd = vim.fn.input "Shell command % "

                if #cmd == 0 then
                    print "no command provided"
                    return
                end

                run_buffer(buffer.current(), cmd, "qf")
            end,
        },
    },

    lsp = {
        inherit = true,
        info = {
            "li",
            ":LspInfo<CR>",
            "lsp info",
        },
        stop_lsp = {
            "lL",
            ":LspStop<CR>",
            "stop lsp",
        },
        restart_lsp = {
            "l!",
            ":LspRestart<CR>",
            "restart lsp",
        },
        start_lsp = {
            "ll",
            ":LspStart<CR>",
            "start lsp",
        },
    },
})

kbd.map("n", "<leader>bH", function()
    buffer.history.print()
end, { desc = "(pop N and) open recent" })

kbd.map("n", "<leader>bh", function()
    local n = vim.v.count

    if n == 0 then
        buffer.history.open()
    else
        buffer.history.pop_open(n)
    end
end, { desc = "(pop N and) open recent" })

return function()
    kbd.map_groups(user.mappings)
end
