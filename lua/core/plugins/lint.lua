local nvimlint = require "lint"
local plug = plugin.lint

local function get_linters()
  local linters = {}
  for lang, conf in pairs(Filetype.ft) do
    if conf.linters and #conf.linters > 0 then
      linters[lang] = array.tolist(conf.linters)
    end
  end

  return linters
end

plug.methods = {
  get_linters = get_linters,
  lint_buffer = plug:wrap(function(self, bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    buffer.call(bufnr, function() 
      if require('lint').linters_by_ft[vim.bo.filetype] then
        require("lint").try_lint() 
      end
    end)
  end)
}

plug.config = {
  linters_by_ft = get_linters(),
}

plug.kbd = {
  {'n', '<leader>ll', plug.methods.lint_buffer, 'Lint buffer'}
}

plug.autocmds = {
  lint_buffer = {'BufWritePost', {
    pattern = '*',
    callback = plug.methods.lint_buffer,
  }}
}

function plug:setup()
  nvimlint.linters_by_ft = self.config.linters_by_ft
end
