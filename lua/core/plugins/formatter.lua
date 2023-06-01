local function get_formatters() 
  local fmt = Filetype.get "formatters" 
  dict.each(fmt, function (ft, conf)
    if is_a.string(conf) then
      return require('formatter.filetypes.' .. ft)[conf]
    else
      return conf
    end
  end)

  return fmt
end

plugin.formatter = {
  kbd = {
    {
      "n",
      "<leader>bf",
      ":FormatWrite<CR>",
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
