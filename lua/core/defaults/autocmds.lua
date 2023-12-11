au.map("TextYankPost", {
  name = "highlight_on_yank",
  pattern = "*",
  callback = function()
    vim.highlight.on_yank { timeout = 100 }
  end,
})

user.exclude_recent_buffer_filetypes = user.exclude_recent_buffer_filetypes
  or { TelescopePrompt = true, netrw = true, [""] = true }

au.map("BufEnter", {
  pattern = "*",
  callback = function(opts)
    local recent = user.recent_buffer
    local current = opts.buf
    recent = recent or current
    local ft = buffer.filetype(current)

    if user.exclude_recent_buffer_filetypes[ft] then
      return
    end

    user.recent_buffer = current
    if recent == current then
      return
    end

    kbd.map("n", "<leader>bl", function()
      buffer.open(recent)
    end, { buffer = current, desc = "recent buffer" })

    if buffer.exists(recent) then
      kbd.map("n", "<leader>bl", function()
        buffer.open(current)
      end, { buffer = recent, desc = "recent buffer" })
    end
  end,
})

au.map("BufAdd", {
  name = "textwidth_colorcolumn",
  pattern = "*",
  callback = function()
    win.set_option(vim.fn.bufnr(), "colorcolumn", "+2")
  end,
})

au.map("BufAdd", {
  pattern = "*",
  callback = function(opts)
    local bufnr = opts.buf
    local bufname = buffer.name(bufnr)
    local function map_quit()
      buffer.map(bufnr, "ni", "q", "<cmd>hide<CR>")
    end

    if buffer.option(bufnr, "filetype") == "help" then
      map_quit()
      return
    end

    dict.each(user.temp_buffer_patterns, function(_, pat)
      if iscallable(pat) then
        if pat(bufname) then
          map_quit()
        end
      elseif isstring(pat[1]) then
        for i = 1, #pat do
          if bufname:match(pat[i]) then
            map_quit()
            break
          end
        end
      elseif isstring(pat) then
        if bufname:match(pat) then
          map_quit()
        end
      elseif istable(pat) and pat.ft then
        if buffer.option(bufnr, "filetype") == pat.ft then
          map_quit()
        end
      end
    end)
  end,
})

if req2path "user.autocmds" then
  require "user.autocmds"
end
