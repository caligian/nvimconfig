local autopairs = plugin.get "autopairs"

autopairs.config = {
    disable_filetype = { "TelescopePrompt", "spectre_panel", 'lisp', 'clojure', 'scheme' },
    disable_in_macro = false,
    disable_in_visualblock = false,
    disable_in_replace_mode = true,
    ignored_next_char = [=[[%w%%%'%[%"%.`%$]]=],
    enable_moveright = true,
    enable_afterquote = true,
    enable_check_bracket_line = false,
    enable_bracket_in_quote = true,
    enable_abbr = false,
    break_undo = true,
    map_cr = true,
    map_bs = true,
    map_c_h = true,
    map_c_w = true,
    check_ts = true,
    ts_config = {
        lua = { "string" },
        ruby = { "string" },
        python = { "string" },

    },
    fast_wrap = {
        map = "<M-e>",
        chars = { "{", "[", "(", '"', "'" },
        pattern = [=[[`%'%"%>%]%)%}%,]]=],
        end_key = "$",
        keys = "qwertyuiopzxcvbnmasdfghjkl",
        check_comma = true,
        highlight = "Search",
        highlight_grey = "Comment",
    },
}

function autopairs:setup()
    require("nvim-autopairs").setup(self.config)
end

return autopairs
