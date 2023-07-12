local mysql = filetype.get "mysel"
mysql.repl = "mysql"
mysql.server = "sqlls"
mysql.formatter = {
    path.join(os.getenv "HOME", "node_modules", ".bin", "sql-formatter") .. " --fix",
    stdin = true,
}
