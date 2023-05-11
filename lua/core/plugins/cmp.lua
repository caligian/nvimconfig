local cmp = require "cmp"
local cmp_zsh = require "cmp_zsh"

plugin.cmp = {
  config = {
    mapping = {
      ["<C-j>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<C-k>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<C-b>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<C-n>"] = cmp.mapping.select_next_item(),
      ["<C-p>"] = cmp.mapping.select_prev_item(),
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<C-e>"] = cmp.mapping.abort(),
      ["<CR>"] = cmp.mapping.confirm { select = true },
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
  },

  setup = function(self)
    cmp_zsh.setup { zshrc = true, filetypes = { "zsh" } }

    cmp.setup.cmdline("/", {
      sources = cmp.config.sources {
        { name = "nvim_lsp_document_symbol" },
      },
    })

    req "user.plugins.cmp"

    cmp.setup(self.config)
  end,
}
