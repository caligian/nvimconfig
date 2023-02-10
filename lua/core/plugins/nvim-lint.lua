user.plugins["nvim-lint"] = { linters_by_ft = {} }

for lang, conf in pairs(user.lang.langs) do
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

for ft, _ in pairs(user.plugins["nvim-lint"].linters_by_ft) do
	Autocmd("NvimLint", "BufWritePost", ft, require("lint").try_lint)
end

Keybinding.noremap("n", "<leader>ll", require("lint").try_lint, { desc = "Try linting buffer" })
