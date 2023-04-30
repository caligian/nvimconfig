--- Create a buffer object. Requires `buffer`
-- @classmod Buffer

local buffer = require "core.utils.buffer"
local Buffer = class("Buffer", false, { include = buffer, attrib = "bufnr" })

--- Store instances
-- @table user.buffer
user.buffer = user.buffer or {}

--- Hash instances by bufnr
user.buffer.BUFNR = user.buffer.BUFNR or {}

user.buffer.SCRATCH_ID = user.buffer.SCRATCH_ID or 1

--- Constructor 
-- @usage
-- local current = Buffer(vim.fn.bufnr())
--
-- --- current.wo.<window variable>
-- print(current.wvar.number)
--
-- --- current.bo.<buffer variable>
-- print(current.var.buflisted)
--
-- --- current.wo.<window option>
-- print(current.wo.number)
--
-- --- current.bo.<buffer option>
-- print(current.o.buflisted)
--
-- @tparam ?string name Name of the buffer
-- @tparam ?boolean scratch Create scratch buffer?
-- @return self
function Buffer:init(name, scratch)
  if name then
    validate.buffer_expr(is {'number', "string"}, name)
  end

  local bufnr, scratch
  if name and not scratch then
    bufnr = buffer.create(name)
    name = buffer.name(bufnr)
    if name:match '^_scratch_buffer_' then scratch = true end
  elseif scratch then
    scratch = true
    user.buffer.SCRATCH_ID = user.buffer.SCRATCH_ID + 1
    name = name or ("_scratch_buffer_" .. (user.buffer.SCRATCH_ID + 1))
    bufnr = buffer.create(name)
  end

  buffer.InvalidBufferException:throw_unless(buffer.exists(name), name)

  self.bufnr = bufnr
  self.name = name
  self.scratch = scratch
  self.wo = {}
  self.o = {}
  self.var = {}
  self.wvar = {}

  if scratch then
    self:setopts { modified = false, buflisted = false }

    if self:getopt "buftype" ~= "terminal" then
      self:setopt("buftype", "nofile")
    else
      self.terminal = true
      self.scratch = nil
    end
  end

  setmetatable(self.var, {
    __index = function(_, k) return self:getvar(k) end,
    __newindex = function(_, k, v) return self:setvar(k, v) end,
  })

  setmetatable(self.o, {
    __index = function(_, k) return self:getopt(k) end,
    __newindex = function(_, k, v) return self:setopt(k, v) end,
  })

  setmetatable(self.wvar, {
    __index = function(_, k)
      if not self:is_visible() then return end
      return self:getwinvar(k)
    end,

    __newindex = function(_, k, v)
      if not self:is_visible() then return end
      return self:setwinvar(k, v)
    end,
  })

  setmetatable(self.wo, {
    __index = function(_, k)
      if not self:is_visible() then return end
      return self:getwinopt(k)
    end,

    __newindex = function(_, k, v)
      if not self:is_visible() then return end
      return self:setwinopt(k, v)
    end,
  })

  self:update()
end

--- Wipeout buffer and delete instance reference
function Buffer:delete()
  local bufnr = self.bufnr

  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
    user.bookmark.BUFNR[self.bufnr] = nil
  end
end

--- Track buffer instance by its bufnr
function Buffer:update()
  dict.update(user.buffer.BUFNR, { bufnr }, self)
end

--- Get bufnr
function Buffer:__tonumber()
  return self.bufnr
end

--- Get buffer string
function Buffer:__tostring()
  return array.join(self:getbuffer(), "\n")
end

return Buffer
