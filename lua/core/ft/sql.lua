local mysql = "sql"
mysql.repl = "mysql"
mysql.lsp_server = "sqlls"
mysql.formatter = {
	path.join(os.getenv("HOME"), "node_modules", ".bin", "sql-formatter") .. " --fix",
	stdin = false,
}

return mysql
