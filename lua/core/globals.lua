local data_dir = vim.fn.stdpath "data"

merge(user, {
    colorscheme = "material-palenight",
    lsp = user.lsp or {},
    dir = vim.fn.stdpath "config",
    user_dir = path.join(os.getenv "HOME", ".nvim"),
    data_dir = data_dir,
    plugins_dir = path.join(data_dir, "lazy"),
    plugins = user.plugins or {},
    shell = "/bin/bash",
    temp_buffer_patterns = {
        qflist = { ft = "qf" },
        temp_buffers = "^__",
        vim_help = "/usr/share/nvim/runtime/doc",
        help_files = { ft = "help" },
        log_files = "%.log$",
        startuptime = {ft = 'startuptime'},
    },
})

req "user.globals"
