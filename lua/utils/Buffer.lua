--- Buffer object creater. This does not YET cover all the neovim buffer API functions

require 'utils.buffers'

Buffer = Class.new("Buffer", false, {
  include = buffers,
  attrib = 'bufnr',
})

Buffer.ids = Buffer.ids or {}
Buffer._scratch_id = Buffer._scratch_id or 1

function Buffer:init(name, scratch)
  local bufnr

  if not name then
    scratch = true
    name = "_scratch_buffer_" .. Buffer._scratch_id + 1
  end

  if is_a.n(name) then
    assert(vim.fn.bufexists(name) ~= 0, "invalid bufnr given: " .. tostring(name))
    bufnr = name
    name = vim.fn.bufname(bufnr)
  else
    bufnr = vim.fn.bufadd(name)
  end

  for key, value in pairs(buffer) do
    if is_callable(value) then
      self[key] = function(_self, ...)
        return value(_self.bufnr, ...)
      end
    end
  end

  self.bufnr = bufnr
  self.name = name
  self.fullname = vim.fn.bufname(bufnr)
  self.scratch = scratch
  self.wo = {}
  self.o = {}
  self.var = {}
  self.wvar = {}

  if scratch then
    Buffer._scratch_id = Buffer._scratch_id + 1
    self:setopts {
      modified = false,
      buflisted = false,
    }
    if self:getopt "buftype" ~= "terminal" then
      self:setopt("buftype", "nofile")
    else
      self.terminal = true
      self.scratch = nil
    end
  end

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

  self:update()
end

function Buffer:delete()
  local bufnr = self.bufnr

  if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
    self.ids[self.bufnr] = nil
  end
end

function Buffer:update()
  table.update(Buffer.ids, { bufnr }, self)
end
