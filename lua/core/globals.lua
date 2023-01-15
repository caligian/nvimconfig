add_global('user', {
    log = {},
    builtin = {
        lsp = {},
        treesitter = {},
        telescope = {},
        color = {},
        compiler = {},
        packages = {},
        kbd = {},
        autocmd = {},
        repl = {},
    },
    config = {},
})

local success, config = pcall(require, 'user')
if success then
    user.config = config
end
