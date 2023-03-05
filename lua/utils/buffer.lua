--- Buffer object creater. This does not YET cover all the neovim buffer API functions

new 'Buffer' {
  ids = {},
  scratch = {},

  exists = function(self)
    return vim.fn.bufexists(self.bufnr) ~= 0
  end,

  update = function (self)
    V.update(Buffer.ids, { self.bufnr }, self)

    if self.scratch then
      V.update(Buffer.scratch, { self.bufnr }, self)
    end
  end,

  getwidth = function(self)
    if not self:is_visible() then
      return
    end

    return vim.fn.winwidth(self:winnr())
  end,

  getheight = function(self)
    if not self:is_visible() then
      return
    end

    return vim.fn.winheight(self:winnr())
  end,

  --- Get buffer option
  -- @tparam string opt Name of the option
  -- @return any
  getopt = function(self, opt)
    assert(self:exists())

    local _, out = pcall(vim.api.nvim_buf_get_option, self.bufnr, opt)

    if out ~= nil then
      return out
    end
  end,

  --- Get buffer option
  -- @tparam string var Name of the variable
  -- @return any
  getvar = function(self, var)
    assert(self:exists())

    ass_s(var, "buffer_var")

    local _, out = pcall(vim.api.nvim_buf_get_var, self.bufnr, var)

    if out ~= nil then
      return out
    end
  end,

  setvar = function(self, k, v)
    assert(self:exists())
    ass_s(k, "buffer_var")
    assert(v, "No value provided")

    vim.api.nvim_buf_set_var(self.bufnr, k, v)
  end,

  --- Set buffer variables
  -- @tparam table vars Dictionary of var name and value
  setvars = function(self, vars)
    assert(self:exists())
    ass_t(vars, "buffer_vars")
    assert(V.ist(vars))

    V.teach(vars, V.partial(self.setvar, self))

    return vars
  end,

  --- Get buffer window option
  -- @tparam string opt Name of the option
  -- @return any
  getwinopt = function(self, opt)
    assert(self:exists())
    ass_s(opt, "option")

    if not self:is_visible() then
      return
    end

    local _, out = pcall(vim.api.nvim_win_get_option, self:winnr(), opt)

    if out ~= nil then
      return out
    end
  end,

  --- Get buffer window option
  -- @tparam string var Name of the variable
  -- @return any
  getwinvar = function(self, var)
    assert(self:exists())

    if not self:is_visible() then
      return
    end

    local _, out = pcall(vim.api.nvim_win_get_var, self:winnr(), var)

    if out then
      return out
    end
  end,

  setwinvar = function(self, k, v)
    assert(self:exists())

    if not self:is_visible() then
      return
    end

    vim.api.nvim_win_set_var(self:winnr(), k, v)
  end,

  setwinvars = function(self, vars)
    assert(self:exists())
    ass_t(vars, "window_vars")

    if not self:is_visible() then
      return
    end

    V.teach(vars, V.partial(self.setwinvar, self))

    return vars
  end,

  setopt = function(self, k, v)
    assert(self:exists())

    vim.api.nvim_buf_set_option(self.bufnr, k, v)
  end,

  setopts = function(self, opts)
    assert(self:exists())

    V.teach(opts, function(k, v)
      self:setopt(k, v)
    end)
  end,

  winnr = function(self)
    assert(self:exists())

    local winnr = vim.fn.bufwinnr(self.bufnr)
    if winnr == -1 then
      return
    end
    return winnr
  end,

  winid = function(self)
    assert(self:exists())

    local winid = vim.fn.bufwinid(self.bufnr)
    if winid == -1 then
      return
    end
    return winid
  end,

  focus = function(self)
    assert(self:exists())

    local winid = self:winid()
    if winid then
      vim.fn.win_gotoid(winid)
      return true
    end
  end,

  setwinopt = function(self, k, v)
    assert(self:exists())
    ass_s(k, "window_option")
    assert(v)

    if not self:is_visible() then
      return
    end

    vim.api.nvim_win_set_option(self:winnr(), k, v)

    return v
  end,

  setwinopts = function(self, opts)
    assert(self:exists())
    ass_t(opts, "window_options")

    if not self:is_visible() then
      return
    end

    V.teach(opts, function(k, v)
      self:setwinopt(k, v)
    end)

    return opts
  end,

  --- Make a new buffer local mapping.
  -- @param mode Mode to bind in
  -- @param lhs Keys to bind callback to
  -- @tparam function|string callback Callback to be bound to keys
  -- @tparam[opt] table opts Additional vim.keymap.set options. You cannot set opts.pattern as it will be automatically set by this function
  -- @return object Keybinding object
  map = function(self, mode, lhs, callback, opts)
    assert(self:exists())

    opts = opts or {}
    opts.buffer = self.bufnr
    return Keybinding.map(mode, lhs, callback, opts)
  end,

  --- Create a nonrecursive mapping
  -- @see map
  noremap = function(self, mode, lhs, callback, opts)
    assert(self:exists())

    opts = opts or {}
    if isa.s(opts) then
      opts = { desc = opts }
    end
    opts.buffer = self.bufnr
    opts.noremap = true
    self:map(mode, lhs, callback, opts)
  end,

  --- Split current window and focus this buffer
  -- @param[opt='s'] split Direction to split in: 's' or 'v'
  split = function(self, split, opts)
    assert(self:exists())

    opts = opts or {}
    split = split or "s"

    V.ass_s(split, "split")
    V.ass_t(opts, "options")

    local required
    local reverse = opts.reverse
    local width = opts.resize or 0.5
    local height = opts.resize or 0.5
    local min = opts.min or 0.01

    -- Use decimal values to use percentage changes
    if split == "s" then
      height = height or 0.5
      local current = vim.fn.winheight(vim.fn.winnr())

      assert(height ~= 0, "height cannot be 0")
      assert(height > 0, "height cannot be < 0")

      if height < 1 then
        required = math.floor(current * height)
      else
        required = math.floor(current)
      end

      if min < 1 then
        min = math.floor(current * min)
      else
        min = math.floor(min)
      end

      if required < min then
        required = min
      end

      if reverse then
        vim.cmd("split | b " .. self.bufnr)
      else
        vim.cmd(V.sprintf("split | wincmd j | b %d", self.bufnr))
      end
      vim.cmd("resize " .. required)
    elseif split == "v" then
      width = width or 0.5
      local current = vim.fn.winwidth(vim.fn.winnr())

      assert(width ~= 0, "width cannot be 0")
      assert(width > 0, "width cannot be < 0")

      if width < 1 then
        required = math.floor(current * width)
      else
        required = math.floor(current)
      end

      if min < 1 then
        min = math.floor(current * min)
      else
        min = math.floor(min)
      end

      if required < min then
        required = min
      end

      if reverse then
        vim.cmd("vsplit | b " .. self.bufnr)
      else
        vim.cmd(V.sprintf("vsplit | wincmd l | b %d", self.bufnr))
      end
      vim.cmd("vert resize " .. required)
    else
      vim.cmd(sprintf("tabnew | b %d", self.bufnr))
    end
  end,

  --- Create a buffer local autocommand. The  pattern will be automatically set to '<buffer=%d>'
  -- @see autocmd._init
  hook = function(self, event, callback, opts)
    assert(self:exists())

    opts = opts or {}

    assert(event, "No event provided")
    assert(callback, "No callback provided")

    return Autocmd(
    event,
    V.merge(opts, {
      pattern = sprintf("<buffer=%d>", self.bufnr),
      callback = callback,
    })
    )
  end,

  --- Hide current buffer if visible
  hide = function(self)
    assert(self:exists())

    local winid = vim.fn.bufwinid(self.bufnr)
    if winid ~= -1 then
      local current_tab = vim.api.nvim_get_current_tabpage()
      local n_wins = #(vim.api.nvim_tabpage_list_wins(current_tab))
      if n_wins > 1 then
        vim.fn.win_gotoid(winid)
        vim.cmd("hide")
      end
    end
  end,

  ---  Is buffer visible?
  --  @return boolean
  is_visible = function(self)
    assert(self:exists())
    return vim.fn.bufwinid(self.bufnr) ~= -1
  end,

  --- Get buffer lines
  -- @param startrow Starting row
  -- @param tillrow Ending row
  -- @return table
  lines = function(self, startrow, tillrow)
    assert(self:exists())

    startrow = startrow or 0
    tillrow = tillrow or -1

    ass.n(startrow, "start_row")
    ass.n(tillrow, "end_row")

    return vim.api.nvim_buf_get_lines(self.bufnr, startrow, tillrow, false)
  end,

  --- Get buffer text
  -- @tparam table start Should be table containing start row and col
  -- @tparam table till Should be table containing end row and col
  -- @param repl Replacement text
  -- @return
  text = function(self, start, till, repl)
    assert(self:exists())
    ass_t(start, "start_cood")
    ass_t(till, "end_cood")
    assert(repl)

    if V.isa(repl) == "string" then
      repl = vim.split(repl, "[\n\r]")
    end

    local a, b = unpack(start)
    local m, n = unpack(till)

    return vim.api.nvim_buf_get_text(self.bufnr, a, m, b, n, repl)
  end,

  bind = function(self, opts, ...)
    assert(self:exists())
    ass_t(opts, "opts")

    opts.buffer = self.bufnr

    return Keybinding.bind(opts, ...)
  end,

  --- Set buffer lines
  -- @param startrow Starting row
  -- @param endrow Ending row
  -- @param repl Replacement line[s]
  setlines = function(self, startrow, endrow, repl)
    assert(self:exists())
    assert(startrow)
    assert(endrow)

    if V.isa(repl, "string") then
      repl = vim.split(repl, "[\n\r]")
    end

    vim.api.nvim_buf_set_lines(self.bufnr, startrow, endrow, false, repl)
  end,

  --- Set buffer text
  -- @tparam table start Should be table containing start row and col
  -- @tparam table till Should be table containing end row and col
  -- @tparam string|table repl Replacement text
  set = function(self, start, till, repl)
    assert(self:exists())
    assert(V.isa(start, "table"))
    assert(V.isa(till, "table"))

    vim.api.nvim_buf_set_text(self.bufnr, start[1], till[1], start[2], till[2], repl)
  end,

  --- Switch to this buffer
  switch = function(self)
    assert(self:exists())

    vim.cmd("b " .. self.bufnr)
  end,

  --- Load buffer
  load = function(self)
    assert(self:exists())

    if vim.fn.bufloaded(self.bufnr) == 1 then
      return true
    else
      vim.fn.bufload(self.bufnr)
    end
  end,

  --- Switch to scratch buffer
  -- @param[opt] default If defined then use 'scratch_buffer' or display a menu to select the existing scratch buffer
  switch_to_scratch = function(default)
    if default then
      local b = Buffer("scratch_buffer", true)
      b:switch()

      return b
    else
      vim.ui.select(V.map(vim.fn.bufname, V.keys(Buffer.scratch)), {
        prompt = "Switch to scratch buffer",
      }, function(b)
        vim.cmd("b " .. b)
      end)
    end
  end,

  --- Open scratch buffer in split
  -- @param[opt='scratch_buffer'] name Name of the scratch buffer
  -- @param split 's' (vertically) or 'v' (horizontally)
  -- @return self
  open_scratch = function(name, split)
    name = name or "scratch_buffer"
    local buf = Buffer(name, true)
    buf:split(split or "s")

    return buf
  end,

  --- Call callback on buffer and return result
  -- @param cb Function to call in this buffer
  -- @return self
  call = function(self, cb)
    assert(self:exists())

    return vim.api.nvim_buf_call(self.bufnr, cb)
  end,

  --- Get buffer-local keymap.
  -- @see V.buffer_has_keymap
  getmap = function(self, mode, lhs)
    assert(self:exists())

    return V.buffer_has_keymap(self.bufnr, mode, lhs)
  end,

  --- Return visually highlighted range in this buffer
  -- @see V.visualrange
  range = function(self)
    assert(self:exists())

    return V.visualrange(self.bufnr)
  end,

  linecount = function(self)
    assert(self:exists())

    return vim.api.nvim_buf_line_count(self.bufnr)
  end,

  delete = function(self)
    if self:exists() then
      Buffer.ids[self.bufnr] = nil
      vim.cmd("bwipeout! " .. self.bufnr)
      return self
    end
  end,

  --- Return current linenumber
  -- @return number
  linenum = function(self)
    assert(self:exists())

    return self:call(function()
      return vim.fn.getpos(".")[2]
    end)
  end,

  is_listed = function(self)
    assert(self:exists())

    return vim.fn.buflisted(self.bufnr) ~= 0
  end,

  info = function(self)
    assert(self:exists())

    return vim.fn.getbufinfo(self.bufnr)
  end,

  wininfo = function(self)
    assert(self:exists())
    if not self:is_visible() then
      return
    end
    return vim.fn.getwininfo(self:winid())
  end,

  string = function(self)
    return table.concat(self:lines(0, -1), "\n")
  end,

  setbuffer = function(self, lines)
    return self:setlines(0, -1, lines)
  end,

  current_line = function(self)
    return self:call(function()
      return vim.fn.getline(".")
    end)
  end,

  lines_till_point = function(self)
    return self:call(function()
      local line = vim.fn.line(".")
      return self:lines(0, line)
    end)
  end,

  __tostring = function(self)
    return self:string()
  end,

  append = function(self, lines)
    return self:setlines(-1, -1, lines)
  end,

  prepend = function(self, lines)
    return self:setlines(0, 0, lines)
  end,

  maplines = function(self, f)
    assert(self:exists())
    return V.map(self:lines(0, -1), f)
  end,

  filter = function(self, f)
    assert(self:exists())
    return V.filter(self:lines(0, -1), f)
  end,

  match = function(self, pat)
    assert(self:exists())
    assert(V.iss(pat))

    return V.filter(self:lines(0, -1), function(s)
      return s:match(pat)
    end)
  end,

  readfile = function(self, fname)
    assert(path.exists(fname))

    local s = file.read(fname)
    self:setlines(0, -1, s)
  end,

  insertfile = function(self, fname)
    assert(path.exists(fname))

    local s = file.read(fname)
    self:append(s)
  end,

  save = function(self)
    self:call(function()
      vim.cmd("w! %:p")
    end)
  end,

  shell = function(self, command)
    assert(V.iss(command))

    self:call(function()
      vim.cmd(":%! " .. command)
    end)

    return self:lines()
  end,

  __add = function(self, s)
    self:append(s)

    return self
  end,

  menu = function(desc, items, formatter, callback)
    ass.st(desc, "description")
    ass.st(items, "items")
    ass.fb(formatter, "formatter")
    ass.f(callback, "callback")

    if V.iss(items) then
      items = vim.split(items, "\n")
    end

    if V.iss(desc) then
      desc = vim.split(desc, "\n")
    end

    local b = Buffer()
    local desc_n = #desc
    local s = table.extend(desc, items)
    local lines = V.copy(s)

    if formatter then
      s = table.map(s, formatter)
    end

    local _callback = callback
    callback = function()
      local idx = vim.fn.line(".")
      if idx <= desc_n then
        return
      end

      _callback(lines[idx])
      b:delete()
    end

    b:setbuffer(s)
    b:setopt("modifiable", false)
    b:hook("WinLeave", V.partial(b.delete, b))
    b:bind(
    { noremap = true, event = "BufEnter" },
    { "q", V.partial(b.delete, b) },
    { "<CR>", callback, "Run callback" }
    )
    return b
  end,

  --- Open buffer and run callback when keys are pressed
  -- @param[opt=false] name Name of the scratch buffer. If skipped then create a unique id
  -- @param text Text to display in the input buffer
  -- @param cb Callback to run at keypress
  -- @param opts Contains other options
  -- @usage Buffer.input(name, text, cb, {
    --   -- Split vertically or horizontally?
    --   split = 's' or 'v'
    --
    --   -- Comments start with ? (default: #)
    --   comment = '#' or string
    --
    --   -- When to run callback?
    --   keys = 'gx' or string
    -- })
    -- @return Buffer
    input = function(text, cb, opts)
      ass.st(text, "text")
      ass.f(cb, "callback")

      opts = opts or {}
      ass.t(opts, "options")

      local split = opts.split or "s"
      local trigger_keys = opts.keys or "gx"
      local comment = opts.comment or "#"

      if V.isa(text, "string") then
        text = vim.split(text, "\n")
      end

      local buf = Buffer()
      buf:setlines(0, -1, text)
      buf:split(split, { reverse = opts.reverse, resize = opts.resize })
      buf:noremap("n", "gq", V.partial(buf.hide, buf), "Close buffer")
      buf:noremap("n", trigger_keys, function()
        local lines = buf:lines(0, -1)
        local sanitized = {}
        local idx = 1

        V.each(lines, function(s)
          if not s:match("^" .. comment) then
            sanitized[idx] = s
            idx = idx + 1
          end
        end)

        cb(sanitized)
        buf:delete()
      end, "Execute callback")

      buf:hook("WinLeave", partial(buf.delete, buf))
    end,

    --- Constructor function returning a buffer object
    -- @param name Name of the buffer
    -- @param[opt] scratch Is a scratch buffer?
    -- @return self
    _init = function(self, name, scratch)
      if not name then
        scratch = true
      end

      local bufnr
      if not name and scratch then
        bufnr = vim.api.nvim_create_buf(false, true)
      elseif scratch then
        bufnr = vim.fn.bufnr(name, true)
      else
        ass_s(name, "buffer_name")
        bufnr = vim.fn.bufnr(name, true)
      end

      if Buffer.ids[bufnr] then
        return Buffer.ids[bufnr]
      end

      self.bufnr = bufnr
      if scratch then
        self:setopts({
          buflisted = false,
          modified = false,
          buftype = "nofile",
        })
      end

      self.fullname = vim.fn.bufname(bufnr)
      self.scratch = scratch
      self.name = name
      self.wo = {}
      self.o = {}
      self.var = {}
      self.wvar = {}

      setmetatable(self.var, {
        __index = function(_, k)
          return self:getvar(k)
        end,
        __newindex = function(_, k, v)
          return self:setvar(k, v)
        end,
      })

      setmetatable(self.o, {
        __index = function(_, k)
          return self:getopt(k)
        end,

        __newindex = function(_, k, v)
          return self:setopt(k, v)
        end,
      })

      setmetatable(self.wvar, {
        __index = function(_, k)
          if not self:is_visible() then
            return
          end

          return self:getwinvar(k)
        end,

        __newindex = function(_, k, v)
          if not self:is_visible() then
            return
          end

          return self:setwinvar(k, v)
        end,
      })

      setmetatable(self.wo, {
        __index = function(_, k)
          if not self:is_visible() then
            return
          end

          return self:getwinopt(k)
        end,

        __newindex = function(_, k, v)
          if not self:is_visible() then
            return
          end

          return self:setwinopt(k, v)
        end,
      })

      self:update(self)

      return self
    end,
    -- TODO: Add other buffer operations (if possible)
    -- TODO: Add window operations
  }
