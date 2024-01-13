return {
  setup = function (self)
    list.each(Filetype.list(), function(x)
      Filetype(x):require():setup_lsp()
    end)
  end
}
