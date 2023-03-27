local nvimlint = require "lint"

user.plugins["nvim-lint"] = {
  config = {
    linters_by_ft = {},
  },
}

local config = user.plugins["nvim-lint"].config

for lang, conf in pairs(Lang.langs) do
  if conf.linters and #conf.linters > 0 then
    config.linters_by_ft[lang] = table.tolist(conf.linters)
  end
end

-- require user config
req "user.plugins.nvim-lint"

-- Setup nvim-lint
nvimlint.linters_by_ft = config.linters_by_ft

-- autocommand
local callback = function()
  if nvimlint.linters_by_ft[vim.bo.filetype] then
    require("lint").try_lint()
  end
end

Autocmd("BufWritePost", {
  pattern = "*",
  callback = callback,
  name = "lint_buffer",
})

Keybinding.noremap("n", "<leader>ll", function()
  print "Linting buffer..."
  callback()
end, { desc = "Try linting buffer", name = "lint_buffer" })
