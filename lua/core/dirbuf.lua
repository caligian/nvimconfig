user.dirbufs = {}

Dirbuf = class("DirBuf", {})
local job = Job

local function persistent(self)
  if not Buffer.exists(self.buffer) then
    local buf = Buffer.create(self.buffer_name)
    self.buffer = Buffer(buf)
  end

  return self.buffer
end

function Dirbuf:get_marked_paths()
  return values(dict.map(self.marked, function(key, _)
    return self.children[key-2]
  end))
end

function Dirbuf:unmark_all_paths()
  dict.each(self.marked, function(row, _)
    self:unmark_path(row)
  end)
end

function Dirbuf:get_cursor_pos()
  local buf = persistent(self)
  local row = buf:row()
  return row
end

local function is_path_marked(p)
  local len = #p
  local ok = p:sub(1, 1) == "[" and p:sub(len, len) == "]"
  return ok
end

local function mark_path(p)
  return "[" .. p .. "]"
end

local function unmark_path(p)
  return p:sub(2, #p - 1)
end

function Dirbuf:unmark_path(row)
  assert_is_a.number(row)

  if row < 3 then
    return
  end

  local line

  if not row then
    return
  else
    line = vim.fn.getline(row)

    if not self.marked[row] or not is_path_marked(line) then
      return true
    end
  end

  line = unmark_path(line)
  local buf = self.buffer


  Buffer.set_option(self.buffer, "modifiable", true)
  Buffer.set(self.buffer, { row - 1, row }, { line })
  Buffer.set_option(self.buffer, "modifiable", false)

    self.marked[row] = nil

  return true
end

function Dirbuf:mark_path(row)
  assert_is_a.number(row)

  local line

  if not row then
    return
  elseif row < 3 then
    return
  else
    line = vim.fn.getline(row)

    if self.marked[row] or is_path_marked(line) then
      return true
    end
  end

  line = mark_path(line)

  Buffer.set_option(self.buffer, "modifiable", true)
  Buffer.set(self.buffer, { row - 1, row }, { line })
  Buffer.set_option(self.buffer, "modifiable", false)

  self.marked[row] = true

  return row
end

function Dirbuf:mark_path_at_cursor()
  local row, _ = self:get_path_at_cursor()

  if row then
    return self:mark_path(row)
  end
end

function Dirbuf:unmark_path_at_cursor()
  local row, _ = self:get_path_at_cursor()
  if row then
    return self:unmark_path(row)
  end
end

function Dirbuf:cd(row)
  local child = is_number(row) and self.children[row] or row

  if not child then
    return
  elseif not Path.is_dir(child) then
    return
  end

  local cmd = 'chdir ' .. child 
  vim.cmd(cmd)

  return child
end

function Dirbuf:cursor_cd()
  self:cd(self:get_cursor_pos())
end

function Dirbuf:set_default_mappings()
  self.mappings.cd = self:noremap("n", "C", function()
    self:cursor_cd()
  end, "cd")

  self.mappings.unmark_all = self:noremap("n", "U", function()
    self:unmark_all_paths()
  end, "unmark all paths")

  self.mappings.show_marked = self:noremap("n", "P", function()
    tostderr(join(self:get_marked_paths(), "\n"))
  end, "display marked path")

  self.mappings.print_filename = self:noremap("n", "p", function()
    pp(self:get_path_at_cursor())
  end, "display path")

  self.mappings.unmark = self:noremap("n", "u", function()
    self:unmark_path_at_cursor()
    vim.cmd 'normal! j'
  end, "unmark child at cursor")

  self.mappings.go_back = self:noremap("n", "-", function()
    local bufname = Buffer.name(Buffer.current())
    bufname = bufname:gsub('^Dirbuf:', '')
    local go_back_to = Path.dirname(bufname)

    if not go_back_to then
      return
    elseif not go_back_to then
      tostderr('reached end of tree')
    else
      if go_back_to == '/' then
        if os.getenv('USER') ~= 'root' then
          tostderr('cannot traverse / without sudo')
          return
        end
      end

      local obj = Dirbuf(go_back_to)
      self:hide()
      obj:show()
    end
  end, "mark child at cursor")

  self.mappings.enter_path = self:noremap("n", "<CR>", function()
    local row, p = self:get_path_at_cursor()

    if row < 3 then
      vim.cmd('normal! 3G')
      return
    end

    if not p then
      return
    elseif Path.is_dir(p) then
      local obj = Dirbuf(p)
      self:hide()
      obj:show()
    else
      tostderr('not a dir: ' .. tostring(p))
    end
  end, "mark child at cursor")

  self.mappings.mark = self:noremap("n", "<Tab>", function()
    self:mark_path_at_cursor()
    vim.cmd 'normal! j'
  end, "mark child at cursor")

  return self.mappings
end

function Dirbuf:noremap(mode, ks, callback, opts)
  opts = is_string(opts) and { desc = opts } or opts or {}
  opts.buffer = persistent(self)
  local map = Kbd.buffer.noremap(persistent(self), mode, ks, callback, opts)
  return map
end

function Dirbuf:map(mode, ks, callback, opts)
  opts = is_string(opts) and { desc = opts } or opts or {}
  opts.buffer = persistent(self)

  local cb = callback
  function callback()
    cb(self.buffer)
  end

  return Kbd.buffer.map(buffer, mode, ks, callback, opts)
end

function Dirbuf:create_buffer()
  local buf = self.buffer_name
  buf = Buffer.create(buf)

  Buffer.set_option(buf, "modifiable", true)

  Buffer.map(buf, "n", "q", function ()
    Buffer.unload(buf)
    Buffer.wipeout(buf)
    user.dirbufs[self.on] = nil
  end, { desc = "hide buffer" })

  Autocmd.buffer(buf, {'BufDelete', 'WinClosed'}, {
    callback = function (_)
      Buffer.wipeout(buf)
      Buffer.unload(buf)
      user.dirbufs[self.on] = nil
    end
  })

  Autocmd.buffer(self.buffer, {'BufEnter'}, {callback = function ()
    self:cd(self.on)
  end})

  Buffer.set(buf, { 0, -1 }, {'inside > ' .. self.on, ''})
  Buffer.set(buf, { 2, -1 }, self.children)

  Buffer.set_options(buf, {
    buflisted = true,
    buftype = "nofile",
    modifiable = false,
    filetype = 'Dirbuf',
  })

  self.buffer = buf

  return buf
end

function Dirbuf:show(opts)
  local buf = self:create_buffer()

  if not buf then
    return
  elseif is_empty(self.children) then
    self:ls()
  end

  self:cd(self.on)
  self:set_default_mappings()

  opts = opts or {}
  local split = opts.split
  local float = opts.float

  if not split and not float then
    split = "leftabove vsplit | wincmd h | b {buf} | vert resize 50"
  end

  if split then
    Buffer.split(buf, split)
  else
    Buffer.float(buf, float)
  end
end

function Dirbuf:ls()
  self.children = Path.ls(self.on, true)
  return self.children
end

function Dirbuf:hide()
  if Buffer.is_visible(self.buffer) then
    Buffer.hide(self.buffer)
  end
end

function Dirbuf:init(start_dir)
  if user.dirbufs[start_dir] then
    return user.dirbufs[start_dir]
  end

  if not Path.is_dir(start_dir) then
    error("invalid dir: " .. tostring(start_dir))
  end

  assert_is_a.string(start_dir)

  self.on = start_dir
  self.children = {}
  self.buffer_name = 'Dirbuf:' .. self.on
  self.buffer = self:create_buffer()
  self.mappings = {}
  self.marked = {}

  self:ls()
  self:cd(self.on)

  user.dirbufs[start_dir] = self

  return self
end

home = Dirbuf "/home/caligian"
home:ls()
home:show()
