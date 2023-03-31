require 'core.bookmarks.commands'

K.bind(
  {prefix='<leader>`', noremap=true},
  {'.', ':BookmarksAdd ', 'Add buffer with linenum'},
  {'k', ':BookmarksRemove ', 'Remove buffer with linenum'},
  {'Q', ':BookmarksDelete<CR>', 'Remove all'},
  {'s', ':BookmarksSave<CR>', 'Save all'},
  {'l', ':BookmarksLoad<CR>', 'Load all'},
  {'h', ':BookmarksShow ', 'Show for ?path'},
  {'o', ':BookmarksOpen', 'Open marked path'}
)
