K.bind(
  {noremap=true, prefix='<C-c>b'},
  {'a', Bookmarks.add, 'Add buffer to bookmarks'},
  {'r', Bookmarks.remove, 'Remove buffer from bookmarks'},
  {'?', ':BookmarkShow<CR>', 'Add buffer to bookmarks'},
  {'l', ':BookmarkLoad<CR>', 'Load bookmarks'},
  {'s', ':BookmarkSave<CR>', 'Save bookmarks'}
)
