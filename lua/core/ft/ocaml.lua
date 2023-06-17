filetype.ocaml = {
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
  formatter = {
     "ocamlformat - ",
     stdin = true,
  },
  bo = { tabstop = 2, shiftwidth = 2 },
}
