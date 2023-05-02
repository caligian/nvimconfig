Lang('julia', {
  compile = 'julia',
  repl = 'julia',
  server = {
    name = 'julials',
    config = {
      single_file_support = true,
      cmd = {'julia-lsp', '-e', 'using LanguageServer; runserver()'},
    }
  }, 
})

