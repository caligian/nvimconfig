filetype.mysql = {
  repl = 'mysql',
  server = 'sqlls',
  formatters = {
    exe = path.join(os.getenv('HOME'), 'node_modules', '.bin', 'sql-formatter'),
    args = { '--fix' },
    no_append = false,
  }
}
