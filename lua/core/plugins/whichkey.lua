local wk = require "which-key"
local whichkey = Plugin.get "whichkey"

whichkey.config = {
    plugins = {
        marks = false,
        registers = false,
        spelling = {
            enabled = true,
            suggestions = 10,
        },
        presets = {
            operators = true,
            motions = true,
            text_objects = true,
            windows = true,
            nav = true,
            z = true,
            g = true,
        },
    },
    operators = { gc = "Comments" },
    key_labels = {
        ["<space>"] = "SPC",
        ["<cr>"] = "RET",
        ["<tab>"] = "TAB",
    },
    icons = {
        breadcrumb = "»",
        separator = "➜",
        group = "+",
    },
    popup_mappings = {
        scroll_down = "<c-j>",
        scroll_up = "<c-k>",
    },
    window = {
        border = "none", -- none, single, double, shadow
        position = "bottom", -- bottom, top
        margin = { 1, 0, 1, 0 }, -- extra window margin [top, right, bottom, left]
        padding = { 2, 2, 2, 2 }, -- extra window padding [top, right, bottom, left]
        winblend = 0,
    },
    layout = {
        height = { min = 4, max = 25 },
        width = { min = 20, max = 50 },
        spacing = 3,
        align = "left",
    },
    ignore_missing = false,
    hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "", "^ " },
    show_help = true,
    show_keys = true,
    triggers = "auto",
    -- triggers = {"<leader>"} -- or specify a list manually
    triggers_blacklist = {
        -- list of mode / prefixes that should never be hooked by WhichKey
        -- this is mostly relevant for key maps that start with a native binding
        -- most people should not need to change this
        i = { "j", "k" },
        v = { "j", "k" },
    },
    -- disable the WhichKey popup for certain buf types and file
    -- Disabled by default for Telescope
    disable = {
        buftypes = {},
        filetypes = { "TelescopePrompt" },
    },
}

function whichkey:setup()
    wk.setup(whichkey.config)

    wk.register({
        f = { name = "File" },
        g = { name = "Git" },
        h = { name = "Help", t = { name = "Colorscheme" } },
        r = { name = "REPL" },
        l = { name = "LSP", w = { name = "Workspaces" } },
        t = { name = "Tab" },
        o = { name = "Options" },
        b = { name = "Buffer" },
        x = { name = "Shell" },
        c = { name = "Compile/Build/Test" },
        q = { name = "Quit" },
        e = { name = "Lua eval" },
        m = { name = "Filetype" },
        w = { name = "Windows" },
    }, { prefix = "<leader>" })

    wk.register({
        r = { name = "Single REPL" },
    }, { prefix = "<localleader>" })
end

return whichkey
