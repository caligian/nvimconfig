local function get_formatters() return Filetype.get "formatters" end

plugin.formatter = {
  kbd = {
    {
      "n",
      "<leader>bf",
      ":FormatWriteLock<CR>",
      {
        desc = "Format buffer",
        name = "format_buffer",
      },
    },
  },

  methods = { get_formatters = get_formatters },

  on_attach = function(self) require("formatter").setup(self.config) end,

  config = {
    filetype = get_formatters(),
    logging = true,
    log_level = vim.log.levels.WARN,
  },
}
