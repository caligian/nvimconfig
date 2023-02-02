vim.api.nvim_create_user_command(
    'CompileNvimBuffer',
    builtin.partial(builtin.compile_buffer, false, false),
    {}
)

vim.api.nvim_create_user_command(
    'CompileAndEvalNvimBuffer',
    builtin.partial(builtin.compile_buffer, false, true),
    {}
)
