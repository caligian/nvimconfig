require 'core.bookmarks.commands'

K.bind(
  {prefix='<leader>`', noremap=true},
  {'a', ':BookmarksAddCurrent .<CR>', 'Add current buffer with current line'},
  {'.', ':BookmarksAdd ', 'Add buffer with linenum'},
  {'k', ':BookmarksRemove ', 'Remove buffer with linenum'},
  {'Q', ':BookmarksDelete<CR>', 'Remove all'},
  {'s', ':BookmarksSave<CR>', 'Save all'},
  {'l', ':BookmarksLoad<CR>', 'Load all'},
  {'h', ':BookmarksShow ', 'Show for ?path'},
  {'o', ':BookmarksOpen', 'Open marked path'}
)

function get_path()
  local line = vim.fn.getline('.')
  local p
  local bufnr = vim.fn.bufnr()
  local curdir = vim.api.nvim_buf_get_var(bufnr, 'netrw_curdir')

  if line == '..' then
    return
  elseif line == '.' then
    return curdir
  else
    return curdir .. '/' .. line
  end
end

K.bind(
  {noremap=true, event='FileType', pattern='netrw', localleader=true},  
  {'b', function () Bookmarks.add(get_path()) end, 'Bookmark file'},
  {'B', function () Bookmarks.remove(get_path()) end, 'Remove file from bookmarks'}
)
