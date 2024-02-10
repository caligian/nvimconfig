local nvim_cmp = require "cmp"
local cmp_zsh = require "cmp_zsh"
local luasnip = require "luasnip"
local cmp = {}

require("lspkind").init {
  -- DEPRECATED (use mode instead): enables text annotations
  --
  -- default: true
  -- with_text = true,

  -- defines how annotations are shown
  -- default: symbol
  -- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
  mode = "symbol_text",

  -- default symbol map
  -- can be either 'default' (requires nerd-fonts font) or
  -- 'codicons' for codicon preset (requires vscode-codicons font)
  --
  -- default: 'default'
  preset = "codicons",

  -- override preset symbols
  --
  -- default: {}
  symbol_map = {
    Text = "󰉿",
    Method = "󰆧",
    Function = "󰊕",
    Constructor = "",
    Field = "󰜢",
    Variable = "󰀫",
    Class = "󰠱",
    Interface = "",
    Module = "",
    Property = "󰜢",
    Unit = "󰑭",
    Value = "󰎠",
    Enum = "",
    Keyword = "󰌋",
    Snippet = "",
    Color = "󰏘",
    File = "󰈙",
    Reference = "󰈇",
    Folder = "󰉋",
    EnumMember = "",
    Constant = "󰏿",
    Struct = "󰙅",
    Event = "",
    Operator = "󰆕",
    TypeParameter = "",
  },
}

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
    ["<A-/>"] = nvim_cmp.mapping.complete(),
    ["<C-e>"] = nvim_cmp.mapping.abort(),
    ["<CR>"] = nvim_cmp.mapping.confirm { select = true },
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
  -- window = {
  --   completion = nvim_cmp.config.window.bordered(),
  --   documentation = nvim_cmp.config.window.bordered(),
  --   scrollbar = "║",

  --   documentation = {
  --     border = {
  --       "╭",
  --       "─",
  --       "╮",
  --       "│",
  --       "╯",
  --       "─",
  --       "╰",
  --       "│",
  --     },
  --     scrollbar = "|",
  --     -- other options
  --   },
  -- },
  formatting = {
    format = function(entry, vim_item)
      vim_item.menu = nil
      return vim_item
    end,
  },
}

function cmp:setup()
  cmp_zsh.setup { zshrc = true, filetypes = { "zsh" } }
  nvim_cmp.setup.cmdline("/", {
    sources = nvim_cmp.config.sources {
      { name = "nvim_lsp_document_symbol" },
    },
  })
  nvim_cmp.setup(self.config)
end

return cmp
