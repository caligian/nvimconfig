local cmp = require("cmp")
local cmp_ultisnips_mappings = require("cmp_nvim_ultisnips.mappings")
local cmp_zsh = require("cmp_zsh")

cmp_zsh.setup({ zshrc = true, filetypes = { "zsh" } })

user.plugins["nvim-cmp"] = {
  mapping = {
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<C-/>"] = cmp.mapping(function(fallback)
      cmp_ultisnips_mappings.compose({ "expand" })(function() end)
    end),
    ["<C-j>"] = cmp.mapping(function(fallback)
      cmp_ultisnips_mappings.compose({ "jump_forwards" })(function() end)
    end, { "i", "s" }),
    ["<C-k>"] = cmp.mapping(function(fallback)
      cmp_ultisnips_mappings.compose({ "jump_backwards" })(function() end)
    end, { "i", "s" }),
  },
  snippet = {
    expand = function(args)
      vim.fn["UltiSnips#Anon"](args.body)
    end,
  },
  sources = {
    { name = "path" },
    { name = "ultisnips" },
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
}

V.require("user.plugins.nvim-cmp")

cmp.setup(user.plugins["nvim-cmp"])

cmp.setup.cmdline("/", {
  sources = cmp.config.sources({
    { name = "nvim_lsp_document_symbol" },
  }),
})
