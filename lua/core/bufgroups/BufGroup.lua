-- groups are matched by lua pattern
if not BufGroup then
  class "BufGroup"

  BufGroup.groups = {}
  BufGroup.cleaner_timers = {}
end

require "utils.Timer"

function BufGroup:get(name, create, pattern)
  local exists = BufGroup.groups[name]
  if exists then
    return exists
  elseif create then
    return BufGroup(name, pattern)
  end
end

--- constructor for BufGroup
-- @param name Name of the buffer group
-- @param pattern Lua pattern to match against the buffer name
function BufGroup:init(name, pattern)
  self.name = isa("string", name)
  self.pattern = isa("string", pattern)
  self.buffers = {}

  table.update(BufGroup.groups, name, self)
end

---
-- Creates an autocmd to match buffers.
function BufGroup:create_autocmd(force)
  if not force and self.autocmd then return self end

  self.autocmd = Autocmd("BufEnter", {
    pattern = "*",
    callback = function() self:add(vim.fn.bufnr()) end,
  })

  return self.autocmd
end

local function get_buffer(buf)
  local exists = utils.buffer.exists
  if is_a(buf, "number") and exists(buf) then
    return buf, vim.api.nvim_buf_get_name(buf)
  elseif is_a(buf, "string") and exists(buf) then
    return vim.fn.bufnr(buf), buf
  end
end

---
-- Add current buffer to the group if it matches the pcre pattern
-- @param buf bufnr or bufname
-- @return self
function BufGroup:add(buf)
  local bufnr, bufname = get_buffer(buf)
  assert(bufnr, "invalid buffer provided " .. bufname)

  if regex.match(bufname, self.pattern) then
    self.buffers[bufnr] = { bufnr = bufnr, bufname = bufname }
    return bufname
  end

  return false
end

function BufGroup:has(buf)
  local bufnr, bufname = get_buffer(buf)
  if bufnr or bufname then
    return table.get(self.buffers, { bufnr or bufname })
  end
end

function BufGroup:remove(buf)
  local bufnr, bufname = get_buffer(buf)
  if bufnr or bufname then
    local obj = self.buffers[bufnr or bufname]
    if obj then
      self.buffers[bufnr or bufname] = nil
      return obj
    end
  end
end

function BufGroup:test(buf)
  local _, bufname = get_buffer(buf)
  return self.pattern:match(bufname)
    or regex.match(bufname, self.pattern) and bufname
    or false
end

function BufGroup:list()
  return Array.map(table.keys(self.buffers), vim.api.nvim_buf_get_name)
end

function BufGroup:clean()
  if Dict.isblank(self.buffers) then return end

  Dict.each(self.buffers, function(bufnr, _)
    if vim.fn.bufexists(bufnr) == -1 then self.buffers[bufnr] = nil end
  end)
end

---
class "BufGroupPool"

function BufGroupPool:init(name)
  self.name = name
  self.groups = {}
end

function BufGroupPool:add(name, ...)
  self.groups[name] = BufGroup(name, ...)
  self.groups[name]:create_autocmd()
end

function BufGroupPool:list()
  local out = {}
  for name, group in pairs(self.groups) do
    out[name] = group:list()
  end

  return out
end

function BufGroupPool:remove(name, buf)
  if not self.groups[name] then return end

  if buf then self.groups[name]:remove(buf) end

  self.groups[name] = nil
end
