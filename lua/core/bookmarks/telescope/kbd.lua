local M = require "core.bookmarks.telescope.picker"

K.bind({ noremap = true, prefix = "<leader>`" }, { "`", M.run_picker, "Show bookmarks" }, {
  ".",
  function()
    M.run_marks_picker(vim.api.nvim_buf_get_name(vim.fn.bufnr()))
  end,
  "Show buffer marks",
}, {
  "k",
  function()
    M.run_marks_remover_picker(vim.api.nvim_buf_get_name(vim.fn.bufnr()))
  end,
  "Remove buffer marks ",
})
