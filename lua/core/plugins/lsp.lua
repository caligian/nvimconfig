list.each(filetype.list(), function(x)
  filetype(x):setup_lsp()
end)

return {}
