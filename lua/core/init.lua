require "core.globals"
require "core.option"
require "core.netrw"
require "core.plugins"

local function defer_req(s, timeout) vim.defer_fn(partial(req, s), timeout) end
defer_req('core.defaults', 300)
defer_req('core.bufgroups', 150)
defer_req('core.bookmarks', 100)

utils.autocmd('BufRead', {
  pattern = '*',
  once = true,
  callback = function ()
    req 'core.lang'
    req 'core.repl'
  end
})
