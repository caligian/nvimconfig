list.each(Filetype.list(), function(x)
  Filetype(x):setup_lsp()
end)

return {}
