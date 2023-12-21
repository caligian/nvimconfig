require "core.utils.kbd"

--- @class Buffer
--- @field id number
--- @field name string
--- @field is_scratch boolean
--- @field is_floating boolean
--- @field mappings? kbd

--- @class Buffer.float : Buffer

Buffer = class "Buffer"
Buffer.float = class "Buffer.float"
Buffer.history = module()
Buffer.recent = ""

dict.merge(Buffer, nvim.buf)
dict.merge(Buffer.float, nvim.buf)

--- Is object a Buffer
--- @param self any
--- @return boolean
function Buffer.isa(self)
  return istable(self) and typeof(self) == "Buffer"
    or typeof(self) == "Buffer.float"
end

--- @param self Buffer|Buffer.float|string|number
--- @return string?
function Buffer.to_name(self)
  assertisa(self, union(Buffer.isa, "string", "number"))

  local bufnr
  if istable(self) then
    bufnr = self.id --[[@as Buffer]]
  else
    bufnr = vim.fn.bufnr(self --[[@as number]])
  end

  local ok = vim.fn.bufnr(bufnr --[[@as number]]) ~= -1
    and nvim.buf.get_name(bufnr)

  return defined(ok)
end

--- @param self Buffer|Buffer.float|string|number
--- @return number?
function Buffer.to_bufnr(self)
  assertisa(self, union(Buffer.isa, "string", "number"))

  local bufnr
  if istable(self) then
    bufnr = self.id
  elseif isstring(self) then
    bufnr = vim.fn.bufnr(self --[[@as number]])
  else
    bufnr = self
  end

  local ok = vim.fn.bufnr(bufnr --[[@as number]]) ~= -1
    and bufnr

  return defined(ok)
end

function Buffer:init(bufnr_or_name, scratch, listed)
  params {
    bufid = {
      function(x)
        assertisa(
          x,
          union(
            "string",
            "number",
            "Buffer",
            "Buffer.float"
          )
        )

        if isnumber(x) then
          if not Buffer.to_bufnr(x) then
            return false,
              "expected valid buffer, got " .. dump(x)
          end
        end

        return true
      end,
      bufnr_or_name,
    },
    ["scratch?"] = { "boolean", scratch },
    ["listed?"] = { "boolean", listed },
  }

  if Buffer.isa(bufnr_or_name) and Buffer.to_bufnr(bufnr_or_name) then
    return bufnr_or_name
  end

  if isstring(bufnr_or_name) then
    bufnr = vim.fn.bufadd(bufnr_or_name)
  else
    bufnr = Buffer.to_bufnr(bufnr_or_name)
  end

  self.id = bufnr
  self.name = vim.fn.bufname(bufnr)
  self.is_scratch = scratch
  self.is_listed = listed
  self.float = nil
  self.history = nil
  self.recent = nil
  self.mappings = {}

  if self.scratch then
    nvim.buf.set_keymap(
      bufnr,
      "n",
      "q",
      ":hide<CR>",
      { desc = "hide buffer", noremap = true }
    )

    nvim.buf.set_option(bufnr, "bufhidden", "wipe")
  end

  nvim.buf.set_option(
    bufnr,
    "buflisted",
    listed and true or false
  )

  return self
end

function Buffer.float:init(...)
  self = Buffer(...)
  self.floating = true

  return self
end

function Buffer.map(self, mode, keys, cb, opts)
  opts = opts or {}
  opts = isstring(opts) and {desc = opts} or opts
  opts.buffer = Buffer.to_bufnr(self)

  local k = kbd.map(mode, keys, cb, opts)
  if Buffer.isa(self) and opts.name then
    self.mappings[opts.name] = k
  end

  return k
end

function Buffer.noremap(self, mode, keys, cb, opts)
  opts = opts or {}
  opts = isstring(opts) and {desc = opts} or opts
  opts.buffer = Buffer.to_bufnr(self)
  opts.noremap = true

  local k = kbd.map(mode, keys, cb, opts)
  if Buffer.isa(self) and opts.name then
    self.mappings[opts.name] = k
  end

  return k
end

local buf = Buffer(1)
buf:map('n', '<leader>Z', ':echo 1<CR>', {name = 'laude'})
