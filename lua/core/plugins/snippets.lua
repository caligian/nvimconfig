local snippets = plugin.get 'snippets'

snippets.config = {
  history = true,
  enable_autosnippets = true,
}

function snippets:setup()
  vim.cmd [[ 
  imap <silent> <C-_> <Plug>luasnip-expand-snippet

  imap <silent> <C-/> <Plug>luasnip-expand-snippet

  inoremap <silent> <S-Tab> <cmd>lua require'luasnip'.jump(-1)<Cr>

  snoremap <silent> <Tab> <cmd>lua require('luasnip').jump(1)<Cr>

  snoremap <silent> <S-Tab> <cmd>lua require('luasnip').jump(-1)<Cr>
  ]]

  local luasnip = require "luasnip"
  luasnip.setup(self.config)

  require("luasnip.loaders.from_lua").lazy_load()
  require("luasnip.loaders.from_vscode").lazy_load()
  require("luasnip.loaders.from_snipmate").lazy_load()

  require("luasnip.loaders.from_lua").load {
    paths = {
      "~/.config/nvim/snips",
      "~/.nvim/snips",
    },
  }

  require("luasnip.loaders.from_vscode").load {
    paths = {
      "~/.config/nvim/snips",
      "~/.nvim/snips",
    },
  }

  require("luasnip.loaders.from_snipmate").load {
    paths = {
      "~/.config/nvim/snips",
      "~/.nvim/snips",
    },
  }
end
