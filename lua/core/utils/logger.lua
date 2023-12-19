require "logging.file"

logger = logger
  or logging.file {
    filename = path.join(
      os.getenv "HOME",
      ".local",
      "share",
      "nvim",
      "messages"
    ),
    datePattern = "%d-%m-%Y > ",
  }

log = setmetatable({}, {
  __index = function(self, level)
    return function(...)
      return logger:log(logger[level:upper()], ...)
    end
  end,
})

vim.keymap.set("n", "<leader>hl", function()
  vim.cmd(
    ":split | e "
      .. path.join(
        os.getenv "HOME",
        ".local",
        "share",
        "nvim",
        "messages"
      )
  )

  vim.bo.modifiable = false
  vim.bo.filetype = "nvimlog"

  vim.api.nvim_buf_set_keymap(
    vim.fn.bufnr(),
    "n",
    "q",
    ":hide<CR>",
    { desc = "hide buffer" }
  )
end, { desc = "show logs" })

