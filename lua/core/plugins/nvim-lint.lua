user.plugins['nvim-lint'] = { linters_by_ft = {} }

for lang, conf in pairs(user.lang.langs) do
    if conf.linters and #conf.linters > 0 then
        user.plugins['nvim-lint'].linters_by_ft[lang] = conf.linters
    end
end

V.require 'user.plugins.nvim-lint'

local nvimlint = V.require 'lint'
nvimlint.linters_by_ft = user.plugins['nvim-lint'].linters_by_ft

local a = Autocmd('NvimLint')
for ft, _ in pairs(user.plugins['nvim-lint'].linters_by_ft) do
    a:create('BufWritePost', '', require('lint').try_lint)
end

Keybinding.noremap('n', '<leader>ll', require('lint').try_lint, { desc = 'Try linting buffer' })
