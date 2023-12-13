local julia = {}

julia.compile = "julia %s"

julia.repl = "julia"

julia.server = {
  "julials",
  config = {
    autostart = true,
    single_file_support = true,
    cmd = {
      "julia",
      "-e",
      "using LanguageServer; runserver()",
    },
  },
}

return julia

