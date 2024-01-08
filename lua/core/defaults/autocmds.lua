
return {
  highlight_on_yank = {
    "TextYankPost",
    {
      pattern = "*",
      callback = function()
        vim.highlight.on_yank { timeout = 100 }
      end,
    },
  },

  textwidth_colorcolumn = {
    "BufAdd",
    {
      pattern = "*",
      callback = function()
        win.set_option(vim.fn.bufnr(), "colorcolumn", "+2")
      end,
    },
  },

  -- close_temp_buffer_with_q = {
  --   "BufAdd",
  --   {
  --     pattern = "*",
  --     callback = function(opts)
  --       local bufnr = opts.buf
  --       local bufname = Buffer.name(bufnr)

  --       local function map_quit()
  --         Buffer.map(bufnr, "ni", "q", "<cmd>hide<CR>")
  --       end

  --       if Buffer.option(bufnr, "filetype") == "help" then
  --         map_quit()
  --         return
  --       end

  --       assert(dict.is_a(user.temp_buffer_patterns, union("string", "function", "table")))

  --       dict.each(user.temp_buffer_patterns, function(_, pat)
  --         if is_callable(pat) then
  --           if pat(bufname) then
  --             map_quit()
  --           end
  --         elseif is_string(pat[1]) then
  --           for i = 1, #pat do
  --             if bufname:match(pat[i]) then
  --               map_quit()
  --               break
  --             end
  --           end
  --         elseif is_string(pat) then
  --           if bufname:match(pat) then
  --             map_quit()
  --           end
  --         elseif is_table(pat) and pat.ft then
  --           if Buffer.option(bufnr, "filetype") == pat.ft then
  --             map_quit()
  --           end
  --         end
  --       end)
  --     end,
  --   },
  -- },

}
