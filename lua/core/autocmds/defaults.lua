user.builtin.autocmd.create(
'BufEnter',
'*tex',
function() vim.wo.wrap = true end,
{ name = 'enable_window_wrap_in_tex' })
