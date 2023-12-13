return {
  nvim_lua = { "BufAdd", "*.config/nvim*lua" },
  xdg_config = {'BufAdd', os.getenv('HOME') .. '/.config/*'},
  all = {'BufAdd', '*'},
}
