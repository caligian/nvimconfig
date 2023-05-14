plugin.align = {
  kbd = {
    leader = true,
    noremap = true,
    { "=", ":EasyAlign ", { desc = "Align by regexp", name = "align" } },
    {
      "=",
      ":'<,'>EasyAlign ",
      { mode = "v", desc = "Align by regexp", name = "align" },
    },
  },

  on_attach = function(self, opts)
    dict.merge(self, opts or {})
    dict.each(self.config or {}, function(key, value)
      vim.g[key] = value
    end)
  end,
}
