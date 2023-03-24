Lang('ocaml', {
  repl = {
    'ocaml',
    on_input = function (s)
      return table.append(s, ";;")
    end
  },
  server = 'ocamllsp',
  linters = '',
  formatters = {
    {exe = 'ocamlformat', args = {'-'}}
  }, 
  bo = {tabstop=2, shiftwidth=2}
})
