local align = {}

align.mappings = {
  align = {
    "n",
    "<leader>=",
    ":EasyAlign //",
    { desc = "Align by regexp" },
  },
  align_region = {
    "v",
    "<leader>=",
    ":'<,'>EasyAlign //",
    { desc = "Align by regexp" },
  },
}

align.config = {}

function align:setup()
  dict.each(self.config or {}, function(key, value)
    vim.g[key] = value
  end)
end

return align
