require "logging.file"

local log_path = path.join(
  os.getenv "HOME",
  ".local",
  "share",
  "nvim",
  "messages"
)

logger = logging.file {
    filename = log_path,
    datePattern = "%d-%m-%Y > ",
  }

logger.log_path = log_path

vim.keymap.set("n", "<space>hl", function()
  vim.cmd(":split | e " .. log_path)

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

