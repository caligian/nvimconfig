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

user.mappings = {}

dict.merge(user.mappings, {
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
                local bufnr = buffer.bufnr()
                local bufname = buffer.name()
                local ft = vim.bo.filetype

                if #ft == 0 or #bufname == 0 then
                    return
                end

                if not Filetype.filetypes[ft] then
                    pp(sprintf('no formatter defined for ' .. ft))
                else
                    local x = Filetype.filetypes[ft]
                    Filetype.format_buffer(x)
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

                if not Filetype.filetypes[ft] then
                    pp(sprintf('no formatter defined for ' .. ft))
                else
                    local x = Filetype.filetypes[ft]
                    Filetype.format_buffer(x)
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
        recent = {
            "bl",
            ":b#<CR>",
            { desc = "Previously opened buffer" },
        },
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
            "<cmd>NvimEvalTillPoint<CR>",
            { desc = "Lua source till point", name = "source_till_point" },
        },
        region = {
            "ee",
            "<esc><cmd>NvimEvalRegion<CR>",
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
        show_logs = {
            "hl",
            ":ShowLogs<CR>",
            { desc = "Show startup logs" },
        },
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
        hide_others = { "wo", "<C-w>o", "Hide other wins" },
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
                local comment = string.split(vim.bo.commentstring or "#", " ")[1]
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
})

return function()
    kbd.map_groups(user.mappings)
end
