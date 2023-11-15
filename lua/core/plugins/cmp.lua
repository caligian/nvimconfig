local nvim_cmp = require("cmp")
local cmp_zsh = require("cmp_zsh")
local luasnip = require("luasnip")
local lspkind = require("lspkind")
local cmp = plugin.get("cmp")

cmp.config = {
    mapping = {
        ["<C-j>"] = nvim_cmp.mapping(function(fallback)
            if nvim_cmp.visible() then
                nvim_cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            else
                fallback()
            end
        end, { "i", "s" }),
        ["<C-k>"] = nvim_cmp.mapping(function(fallback)
            if nvim_cmp.visible() then
                nvim_cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, { "i", "s" }),
        ["<C-b>"] = nvim_cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = nvim_cmp.mapping.scroll_docs(4),
        ["<C-n>"] = nvim_cmp.mapping.select_next_item(),
        ["<C-p>"] = nvim_cmp.mapping.select_prev_item(),
        ["<C-Space>"] = nvim_cmp.mapping.complete(),
        ["<C-e>"] = nvim_cmp.mapping.abort(),
        ["<CR>"] = nvim_cmp.mapping.confirm({ select = true }),
    },
    snippet = {
        expand = function(args)
            require("luasnip").lsp_expand(args.body)
        end,
    },
    sources = {
        { name = "luasnip" },
        { name = "neorg" },
        { name = "path" },
        { name = "buffer" },
        { name = "treesitter" },
        { name = "nvim_lsp" },
        { name = "nvim_lua" },
        { name = "zsh" },
        { name = "nvim_lsp_signature_help" },
        {
            name = "spell",
            option = {
                keep_all_entries = false,
                enable_in_context = function()
                    return true
                end,
            },
        },
    },
    window = {
        completion = {
            border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
            scrollbar = "║",
        },

        documentation = {
            border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
            scrollbar = "|",
            -- other options
        },
    },
    formatting = {
        format = lspkind.cmp_format({ maxwidth = 50 }),
    },
}

function cmp:setup()
    cmp_zsh.setup({ zshrc = true, filetypes = { "zsh" } })

    nvim_cmp.setup.cmdline("/", {
        sources = nvim_cmp.config.sources({ { name = "nvim_lsp_document_symbol" } }),
    })

    nvim_cmp.setup(self.config)
end

return cmp
