filetype.julia = {
  compile = "julia",
  repl = "julia",
  server = {
    "julials",
    config = {
      autostart = true,
      single_file_support = true,
      cmd = { "julia", "-e", "using LanguageServer; runserver()" },
    },
  },
}
