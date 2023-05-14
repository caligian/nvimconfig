local nvimlint = require "lint"
local plug = plugin.lint

local function get_linters()
  local out = {
    linters = {},
    linters_by_ft = {},
  }

  dict.each(Filetype.get 'linters', function (ft, lintconf)
    if dict.isdict(lintconf) then
      out.linters[ft] = lintconf
      nvimlint.linters[ft] = lintconf
    else
      lintconf = array.tolist(lintconf)
      out.linters_by_ft[ft] = lintconf
      nvimlint.linters_by_ft[ft] = lintconf
    end
  end)

  return out
end

plug.methods = {
  lint_buffer = function(self, bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    buffer.call(bufnr, function()
      if require("lint").linters_by_ft[vim.bo.filetype] then
        require("lint").try_lint()
      end
    end)
  end,
}

plug.config = {
  linters_by_ft = get_linters(),
}

plug.kbd = {
  { "n", "<leader>ll", plug.methods.lint_buffer, "Lint buffer" },
}

function plug:on_attach() 
  get_linters()
end
