local text = {}

text.bo = {
  textwidth = 80,
  formatoptions = 'tqwan1p',
}

text.mappings = {
  format_buffer = {
    'n',
    '<leader>bf',
    function ()
      local bufnr = Buffer.current()
      local lines = Buffer.lines(bufnr, 0, -1)

      for i=1, #lines do
        local line = lines[i]:match('%s+')

        if line then
          lines[i] = lines[i]:gsub('%s+', ' ')
        end
      end

      Buffer.set(bufnr, {0, -1}, lines)
    end,
    {}
  }
}

return text
