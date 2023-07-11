kbd.noremap("n", "<leader>bf", function()
  local ft = vim.bo.filetype
  if #ft == 0 then return end

  local spec = filetype.get(ft, "formatter")
  if not spec then return end

  if dict.is_empty(spec) then
    pp "No formatter defined for current buffer"
    return
  end

  formatter.format(nil, spec)
end, { desc = "format buffer", name = 'format_buffer1' })
