require 'core.utils.au'
require 'core.utils.kbd'
require 'core.utils.telescope'

buffergroup = class 'buffergroup'
buffergroup.buffergroups = {}
buffergroup._buffers = {}

function buffergroup:exclude_buffer(bufnr)
  if buffer.exists(bufnr) then
    self.exclude[bufnr] = true
    self.buffers[bufnr] = nil

    dict.remove()
  end
end

function buffergroup:init(name, event, pattern, opts)
  if buffergroup.buffergroups[name] then
    return buffergroup.buffergroups[name]
  end

  opts = opts or {}
  local exclude = opts.exclude or {}
  self.exclude = exclude
  self.name = name
  self.buffers = {}
  self.au = au.map(event, {
    pattern = pattern,
    callback = function (opts)
      local buf = opts.buf
      if not self.exclude[buf] then
        self.buffers[buf] = true
        dict.set(buffergroup._buffers, {buf, name}, true)
      end
    end
  })

  buffergroup.buffergroups[self.name] = self
  return self
end


pp(buffergroup._buffers)

lua = buffergroup('lua', 'Filetype', 'lua')
pp(lua)
