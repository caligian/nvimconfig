require 'logging.file'

user = {
    logger = logging.file {filename=vim.fn.stdpath('config') .. '/nvim.log'},
    log = {},
    require = function (s)
        local success, err = pcall(require, s)
        if not success then
            user.logger:debug(err)
            user.log[#user.log + 1] = err
        else
            return success
        end
    end,
    builtin = {
        lsp = {
            flags = {
                debounce_text_changes = 150,
            },
            servers = {
                sumneko_lua = {
                    settings = {
                        Lua = { diagnostics = { globals = { 'vim', 'unpack', 'loadfile', 'user' } } },
                    }
                },
                pyright = true,
                solargraph = true,
                texlab = true,
            },
        },
        treesitter = {
            textobjects = {
                move = {
                    enable = true,
                    set_jumps = true, -- whether to set jumps in the jumplist
                    goto_next_start = {
                        ["]m"] = "@function.outer",
                        ["]]"] = { query = "@class.outer", desc = "Next class start" },
                    },
                    goto_next_end = {
                        ["]M"] = "@function.outer",
                        ["]["] = "@class.outer",
                    },
                    goto_previous_start = {
                        ["[m"] = "@function.outer",
                        ["[["] = "@class.outer",
                    },
                    goto_previous_end = {
                        ["[M"] = "@function.outer",
                        ["[]"] = "@class.outer",
                    },
                },
            },
            highlight = {
                -- `false` will disable the whole extension
                enable = true,

                -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
                -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
                -- the name of the parser)
                -- list of language that will be disabled
                disable = {},

                -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
                -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
                -- Using this option may slow down your editor, and you may see some duplicate highlights.
                -- Instead of true it can also be a list of languages
                additional_vim_regex_highlighting = false,
            },
            select = {
                enable = true,

                -- Automatically jump forward to textobj, similar to targets.vim
                lookahead = true,

                keymaps = {
                    -- You can use the capture groups defined in textobjects.scm
                    ["af"] = "@function.outer",
                    ["if"] = "@function.inner",
                    ["ac"] = "@class.outer",
                    -- You can optionally set descriptions to the mappings (used in the desc parameter of
                    -- nvim_buf_set_keymap) which plugins like which-key display
                    ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
                },
                -- You can choose the select mode (default is charwise 'v')
                --
                -- Can also be a function which gets passed a table with the keys
                -- * query_string: eg '@function.inner'
                -- * method: eg 'v' or 'o'
                -- and should return the mode ('v', 'V', or '<c-v>') or a table
                -- mapping query_strings to modes.
                selection_modes = {
                    ['@parameter.outer'] = 'v', -- charwise
                    ['@function.outer'] = 'V', -- linewise
                    ['@class.outer'] = '<c-v>', -- blockwise
                },
                -- If you set this to `true` (default is `false`) then any textobject is
                -- extended to include preceding or succeeding whitespace. Succeeding
                -- whitespace has priority in order to act similarly to eg the built-in
                -- `ap`.
                --
                -- Can also be a function which gets passed a table with the keys
                -- * query_string: eg '@function.inner'
                -- * selection_mode: eg 'v'
                -- and should return true of false
                include_surrounding_whitespace = true,
            },
        },
        telescope = {},
        color = {},
        compiler = {},
        packages = {},
        kbd = {},
        autocmd = {},
        repl = {},
        shell = '/usr/bin/zsh',
        colorscheme = 'OceanicNextLight',
        font = 'Hack Nerd Font:h13'
    },
    config = {},
}

local success, config = pcall(require, 'user')
if success then
    user.config = config
end

local font = user.config.font or user.builtin.font or 'Hack Nerd Font:h12'
vim.o.guifont = font
