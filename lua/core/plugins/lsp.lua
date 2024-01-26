return {
  setup = vim.schedule_wrap(function ()
    Filetype.setup_lsp_all()
  end)
}
