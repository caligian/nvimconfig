local function get_formatters()
  -- We are only using this if LSP formatting is not available
  -- Therefore this will not be setup for all langs
  local formatters = {}

  for lang, conf in pairs(Filetype.ft) do
    if conf.formatters then
      for idx, formatter in ipairs(conf.formatters) do
        if is_a.string(formatter) then
          local out = require(sprintf("formatter.filetypes.%s", lang))
          if out then
            conf.formatters[idx] = out
          else
            conf.formatters[idx] = nil
          end
        end
      end
      formatters[lang] = conf.formatters
    end
  end

  return formatters
end

plugin.formatter = {
  kbd = {
    {
      "n",
      "<leader>bf",
      ":FormatWrite<CR>",
      {
        desc = "Format buffer",
        silent = true,
        name = "format_buffer",
      },
    },
  },

  methods = { get_formatters = get_formatters },

  setup = function(self) require("formatter").setup(self.config) end,

  config = {
    filetype = get_formatters(),
    logging = true,
    log_level = vim.log.levels.WARN,
  },
}
