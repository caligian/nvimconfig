--- Buffer object creater. This does not YET cover all the neovim buffer API functions

local buffer = require "core.utils.buffer"
local Buffer = class("Buffer", false, { include = buffer, attrib = "bufnr" })
user.buffer = user.buffer or { BUFNR = {}, SCRATCH_ID = 1 }
user.buffer.SCRATCH_ID = user.buffer.SCRATCH_ID or 1

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

function Buffer:delete()
  local bufnr = self.bufnr

  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
    user.bookmark.BUFNR[self.bufnr] = nil
  end
end

function Buffer:update()
  dict.update(user.buffer.BUFNR, { bufnr }, self)
end

return Buffer
