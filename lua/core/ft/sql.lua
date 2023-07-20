Filetype.mysql = {
    repl = "mysql",
    server = "sqlls",
    formatter = {
        path.join(os.getenv "HOME", "node_modules", ".bin", "sql-formatter") .. " --fix",
        stdin = false,
    },
}
