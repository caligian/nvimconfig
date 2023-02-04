user.plugins['ultisnips'] = {
    UltiSnipsExpandTrigger = '<C-o>',
    UltiSnipsJumpForwardTrigger = '<C-j>',
    UltiSnipsJumpBackwardTrigger = '<C-k>',
    UltiSnipsEditSplit = 'vertical',
}

V.require 'user.plugins.ultisnips'

for k, v in pairs(user.plugins['ultisnips']) do
    vim.g[k] = v
end
