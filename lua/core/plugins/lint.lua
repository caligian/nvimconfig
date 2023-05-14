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

local function load(self)
  if not self.linters then return end
  local spec = utils.copy(self.linters)

  return dict.merge({
    linters_by_ft = dict.delete(spec, "ft") or dict.delete(x, "filetype"),
  }, spec)
end

plug.methods = {
  lint_buffer = function(self, bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    buffer.call(bufnr, function()
      if require("lint").linters_by_ft[vim.bo.filetype] then
        require("lint").try_lint(bufnr)
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

function plug:setup() nvimlint.linters_by_ft = self.config.linters_by_ft end
