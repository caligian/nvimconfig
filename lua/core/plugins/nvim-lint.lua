user.plugins["nvim-lint"] = { linters_by_ft = {} }

for lang, conf in pairs(Lang.langs) do
  if conf.linters and #conf.linters > 0 then
    user.plugins["nvim-lint"].linters_by_ft[lang] = V.ensure_list(conf.linters)
  end
end

V.require("user.plugins.nvim-lint")

local nvimlint = V.require("lint")

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

local callback = function()
  if nvimlint.linters_by_ft[vim.bo.filetype] then
    require("lint").try_lint()
  end
end

Autocmd("BufWritePost", {
  pattern = "*",
  callback = callback,
})

user.plugins["nvim-lint"].kbd = {
  lint_buffer = Keybinding.noremap("n", "<leader>ll", function()
    print("Linting buffer...")
    callback()
  end, { desc = "Try linting buffer" }),
}

V.require("user.plugins.nvim-lint.kbd")
