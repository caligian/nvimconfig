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

  add_to_recent_buffers = {
    "BufEnter",
    {
      pattern = "*",
      callback = function(opts)
        local recent = user.recent_buffer
        local current = opts.buf
        recent = recent or current
        local ft = Buffer.filetype(current)

        if user.exclude_recent_buffer_filetypes[ft] then
          return
        end

        user.recent_buffer = current
        if recent == current then
          return
        end

        Kbd.map("n", "<leader>bl", function()
          Buffer.open(recent)
        end, {
          buffer = current,
          desc = "recent buffer",
        })

        if Buffer.exists(recent) then
          Kbd.map("n", "<leader>bl", function()
            Buffer.open(current)
          end, {
            buffer = recent,
            desc = "recent buffer",
          })
        end
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

  close_temp_buffer_with_q = {
    "BufAdd",
    {
      pattern = "*",
      callback = function(opts)
        local bufnr = opts.buf
        local bufname = Buffer.name(bufnr)
        local function map_quit()
          Buffer.map(bufnr, "ni", "q", "<cmd>hide<CR>")
        end

        if Buffer.option(bufnr, "filetype") == "help" then
          map_quit()
          return
        end

        assert(dict.is_a(user.temp_buffer_patterns, union("string", "function", "table")))

        dict.each(user.temp_buffer_patterns, function(_, pat)
          if is_callable(pat) then
            if pat(bufname) then
              map_quit()
            end
          elseif is_string(pat[1]) then
            for i = 1, #pat do
              if bufname:match(pat[i]) then
                map_quit()
                break
              end
            end
          elseif is_string(pat) then
            if bufname:match(pat) then
              map_quit()
            end
          elseif is_table(pat) and pat.ft then
            if Buffer.option(bufnr, "filetype") == pat.ft then
              map_quit()
            end
          end
        end)
      end,
    },
  },
}
