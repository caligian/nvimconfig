local ruby = Filetype 'ruby'
ruby.compile = 'ruby'
ruby.repl = 'irb --inf-ruby-mode'
ruby.test = 'rspec'
ruby.lsp_server = 'solargraph'

return ruby
