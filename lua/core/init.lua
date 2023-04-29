local function defer(req_s, timeout)
  vim.defer_fn(function() req(req_s) end, timeout)
end

req "core.globals"
req "core.option"
req "core.lang"
req "core.plugins"
req 'core.bufgroups'

defer('core.netrw', 200)
defer('core.defaults', 250)
defer('core.bookmarks', 200)
defer('core.repl', 400)
