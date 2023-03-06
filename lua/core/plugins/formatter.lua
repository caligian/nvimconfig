-- We are only using this if LSP formatting is not available
-- Therefore this will not be setup for all langs
local formatters = {}

for lang, conf in pairs(Lang.langs) do
  if conf.formatters then
    for idx, formatter in ipairs(conf.formatters) do
      if V.isstring(formatter) then
        local out = V.require(sprintf("formatter.filetypes.%s", lang))
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

-- Setup autocmd for autoformatting
Keybinding.noremap("n", "<leader>bf", "FormatWrite<CR>", {
  event = "FileType",
  pattern = V.keys(formatters),
  desc = "Formatter buffer",
  silent = true,
  name = "format_buffer",
})

Autocmd("BufWritePost", {
  pattern = "*",
  callback = ":silent! FormatWrite",
  name = "format_buffer",
})

-- Finalize setup
user.plugins.formatter = {
  config = {
    filetype = formatters,
    logging = true,
    log_level = vim.log.levels.WARN,
  },
}

V.require("user.plugins.formatter")

require("formatter").setup(user.plugins.formatter.config)
