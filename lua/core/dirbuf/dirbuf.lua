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

function Dirbuf:get_marked()
  return values(dict.map(self.marked, function(key, _)
    return self.children[key-2]
  end))
end

function Dirbuf:unmark_all()
  dict.each(self.marked, function(row, _)
    self:unmark(row)
  end)
end

function Dirbuf:is_marked(row)
  if not self.buffer:exists() then
    return
  end

  local p = self.buffer:get_lines(row-1, row, false)[1]
  local len = #p
  local ok = p:sub(1, 1) == "[" and p:sub(len, len) == "]"

  return ok
end

function Dirbuf:unmark(row)
  if not self.buffer:exists() then
    return
  end

  row = row or self.buffer:row()
  assert_is_a.number(row)

  if row < 3 then
    return
  end

  local line

  if not row then
    return
  else
    line = self.buffer:get_line(row-1)

    if not self.marked[row] or not self:is_marked(row) then
      return true
    end
  end

  line = line:sub(2, #line-1)
  local buf = self.buffer

  self.buffer:set_option("modifiable", true)
  self.buffer:set({ row - 1, row }, { line })
  self.buffer:set_option("modifiable", false)

  self.marked[row] = nil

  return true
end

function Dirbuf:mark(row)
  if not self.buffer:exists() then
    return
  end

  row = row or self.buffer:row()
  assert_is_a.number(row)

  local line

  if not row then
    return
  elseif row < 3 then
    return
  else
    line = self.buffer:get_line(row-1)

    if self.marked[row] or self:is_marked(row) then
      return true
    end
  end

  line = "[" .. line .. "]"

  self.buffer:set_option("modifiable", true)
  self.buffer:set({ row - 1, row }, { line })
  self.buffer:set_option("modifiable", false)

  self.marked[row] = true

  return row
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

function Dirbuf:map(mode, ks, callback, opts)
  opts = is_string(opts) and { desc = opts } or opts or {}
  opts.buffer = persistent(self.buffer)

  if not opts.buffer then
    return
  end

  opts.buffer = self.buffer.buffer_index
  local map = Kbd.buffer.map(persistent(self), mode, ks, callback, opts)

  return map
end

function Dirbuf:noremap(mode, ks, callback, opts)
  opts = is_string(opts) and { desc = opts } or opts or {}
  opts.buffer = persistent(self.buffer)

  if not opts.buffer then
    return
  end

  opts.buffer = self.buffer.buffer_index
  local map = Kbd.buffer.noremap(persistent(self), mode, ks, callback, opts)

  return map
end

function Dirbuf:create_buffer()
  local bufname = 'Dirbuf:' .. self.on
  local buf = Buffer.scratch(bufname, true)
  buf = Buffer(buf)

  if not buf then
    return nil, 'could not create buffer with ' .. tostring(self.on)
  end

  buf:map("n", "q", function ()
    buf:delete()
    user.dirbufs[self.on] = nil
  end, { desc = "hide buffer" })

  buf:autocmd({'WinClosed'}, function ()
    buf:delete()
  end)

  Autocmd.buffer(self.buffer, {'BufEnter'}, {callback = function ()
    self:cd(self.on)
  end})

  self:ls()
  if #self.children == 0 then
    return
  end

  buf:set({0, -1}, {'inside > ' .. self.on, ''})
  buf:set({2, -1}, self.children)

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

  opts = opts or {}
  local split = opts.split
  local float = opts.float

  if not split and not float then
    split = "leftabove vsplit | wincmd h | b {buf} | vert resize 50"
  end

  if split then
    buf:split(split)
  else
    buf:float(float)
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
  self.mappings = {}
  self.marked = {}

  user.dirbufs[start_dir] = self

  return self
end

home = Dirbuf "/home/caligian"
home:ls()
home:show()
