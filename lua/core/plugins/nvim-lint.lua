local nvimlint = V.require("lint")

user.plugins["nvim-lint"] = {
  linters_by_ft = {},
  autocmd = {},
  kbd = {},
}

for lang, conf in pairs(Lang.langs) do
  if conf.linters and #conf.linters > 0 then
    user.plugins["nvim-lint"].linters_by_ft[lang] = V.tolist(conf.linters)
  end
end

local callback = function()
  if nvimlint.linters_by_ft[vim.bo.filetype] then
    require("lint").try_lint()
  end
end

user.plugins["nvim-lint"].lint_on_save = Autocmd("BufWritePost", {
  pattern = "*",
  callback = callback,
})

Keybinding.noremap("n", "<leader>ll", function()
  print("Linting buffer...")
  callback()
end, { desc = "Try linting buffer", name = "lint_buffer" })

V.require("user.plugins.nvim-lint")

-- Setup nvim-lint
nvimlint.linters_by_ft = user.plugins["nvim-lint"].linters_by_ft

-- Ignore globals
nvimlint.linters.luacheck.args = {
  "--cache",
  "--no-max-code-line-length",
  "--std lua51c",
  "-g",
  "-a",
  "--ranges",
  "--formatter plain",
  "-",
}
