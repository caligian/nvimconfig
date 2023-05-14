filetype.rust = {
  repl = {
    "evcxr",
    on_input = function(s)
      s[#s + 1] = "\n"
      return s
    end,
  },
  compile = "cargo run",
  server = "rust_analyzer",
}
