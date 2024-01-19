function user.enable_temp_buffers(overrides)
  if not user.enable.temp_buffers then
    return false
  end

  local temp_buffer_patterns = user.temp_buffer_patterns
    or {
      { pattern = { ".*nvim/.*doc.*txt" } },
      { ft = "help" },
      { ft = "text" },
      "help",
      "*.local/share/nvim/*",
      { "text" },
    }

  dict.merge(temp_buffer_patterns, { overrides })

  local function set_mappings(buf)
    nvim.buf.set_keymap(buf, "n", "q", "", {
      desc = "hide buffer",
      callback = function()
        Buffer.hide(buf)
      end,
    })
  end

  local function default_callback(opts)
    set_mappings(opts.buf)
  end

  local function set_ft_autocmd(ft)
    nvim.create.autocmd({ "Filetype" }, {
      pattern = ft.ft or ft.filetype,
      callback = default_callback,
    })
  end

  local function set_pattern_autocmd(pat)
    nvim.create.autocmd("BufAdd", { callback = default_callback, pattern = pat })
  end

  local function set_lua_pattern_autocmd(pat)
    pat = pat.pat or pat.pattern

    nvim.create.autocmd("BufAdd", {
      callback = function(opts)
        if is_table(pat) then
          for i = 1, #pat do
            if Buffer.name(opts.buf):match(pat[i]) then
              default_callback(opts)
            end
          end
        elseif Buffer.name(opts.buf):match(pat) then
          default_callback(opts)
        end
      end,
      pattern = pat,
    })
  end

  local Rules = case {
    {
      is_string,
      set_pattern_autocmd,
    },
    {
      case.rules.list_of "string",
      set_pattern_autocmd,
    },
    {
      { pat = is_string },
      set_lua_pattern_autocmd,
    },
    {
      { pattern = is_string },
      set_lua_pattern_autocmd,
    },
    {
      { ft = is_string },
      set_ft_autocmd,
      name = "filetype",
    },
    {
      { filetype = is_string },
      set_ft_autocmd,
      name = "filetype",
    },
  }

  for i = 1, #temp_buffer_patterns do
    local obj = temp_buffer_patterns[i]
    Rules:match(obj)
  end

  return true
end

function user.enable_recent_buffers(overrides)
  if not user.enable.buffer_history then
    return false
  end

  local recent_buffer_fts = user.exclude_recent_buffer_filetypes or {}

  dict.merge(recent_buffer_fts, { overrides })

  user.recent_buffer = nil

  user.buffer_history_limit = 1000

  user.buffer_history = {
    add = function(self, buf)
      if #self > 1000 then
        for i = 1, #self do
          self[i] = nil
        end
      end

      if buf == self[#self] then
        return
      end

      self[#self + 1] = buf
    end,
    clean = function(self)
      for i = 1, #self do
        if not Buffer.exists(self[i]) then
          table.remove(self, i)
        end
      end
    end,
    pop = function(self)
      local len = #self
      local prev = self[len]
      local curr = Buffer.current()
      local i = len

      self[i] = nil

      while prev == curr do
        prev = self[i - 1]
        i = i - 1
        self[i] = nil
      end

      return prev
    end,
  }

  nvim.create.autocmd("BufEnter", {
    pattern = "*",
    callback = function(opts)
      local buf = opts.buf
      local ft = Buffer.filetype(buf)

      if ft == "" then
        return
      elseif recent_buffer_fts[ft] then
        return
      end

      user.buffer_history:add(buf)

      if user.recent_buffer and user.recent_buffer ~= buf then
        Kbd.map("n", "<leader>bl", ":b " .. user.recent_buffer .. "<CR>", { desc = "open recent" })
      end

      user.recent_buffer = buf
    end,
  })

  vim.keymap.set("n", "<leader>b<", function()
    local buf = user.buffer_history:pop()
    user.buffer_history:clean()

    if buf then
      Buffer.open(buf)
    else
      print "buffer history empty"
    end
  end, { desc = "last opened" })

  return true
end

function user.setup_defaults()
  if user.enable.plugins then
    Plugin.main()
  end

  user.plugins.colorscheme:setup()
  user.plugins.statusline:setup()

  vim.schedule(function()
    if user.enable.autocmds then
      Autocmd.main()
    end

    if user.enable.filetypes then
      Filetype.main()
    end

    if user.enable.buffer_groups then
      BufferGroup.main()
    end

    if user.enable.bookmarks then
      Bookmark()
      Bookmark.set_mappings()
    end

    if user.enable.repl then
      REPL.main()
    end

    user.enable_temp_buffers()
    user.enable_recent_buffers()

    if user.enable.mappings then
      Kbd.map("n", "<leader>hC", ":ReloadColorscheme<CR>", "reload colorscheme")
      Kbd.map("n", "<leader>h=", ":ReloadStatusline<CR>", "reload statusline")

      if user.enable.commands then
        local cmds = require "core.defaults.commands"

        if req2path "user.commands" then
          dict.merge(cmds, requirex "user.commands")
        end

        dict.each(cmds, function(name, args)
          nvim.create.user_command(name, unpack(args))
        end)
      end
    end
  end)

  vim.defer_fn(function ()
    Kbd.main()
  end, 100)
end


