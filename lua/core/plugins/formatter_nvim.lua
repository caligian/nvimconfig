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

-- Setup formatter
user.plugins["formatter.nvim"] = { filetype = formatters }

-- Finalize setup
require("formatter").setup(user.plugins["formatter.nvim"])

-- Setup autocmd for autoformatting
user.plugins["formatter.nvim"].kbd = {
  format_buffer = Keybinding.noremap(
    "n",
    "<leader>bf",
    "FormatWrite<CR>",
    { event = "FileType", pattern = V.keys(formatters), desc = "Formatter buffer", silent = true }
  ),
}

Autocmd("BufWritePost", {
  pattern = "*",
  callback = ":FormatWrite",
})
