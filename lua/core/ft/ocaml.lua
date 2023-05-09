return {
  repl = {
    "utop",
    on_input = function(s)
      if not s[#s]:match ";;$" then
        return array.append(s, ";;")
      end
      return s
    end,
  },
  server = "ocamllsp",
  formatters = {
    { exe = "ocamlformat", args = { "-" } },
  },
  bo = { tabstop = 2, shiftwidth = 2 },
}