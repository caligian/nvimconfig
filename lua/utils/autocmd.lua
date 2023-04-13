autocmd = autocmd or Class.new('Autocommand')
autocmd.IDS = autocmd.IDS or {}
autocmd.NAMES = autocmd.NAMES or {}

local function hash(event, pattern)
  return sprintf(
    '%s::%s',
    array.join(array.toarray(event), ','),
    array.join(array.toarray(pattern), ',')
  )
end

local function make_state(event, pattern, self)
  autocmd.NAMES[hash(event, pattern)] = self

  array.each(event, function (e)
    autocmd.NAMES[e] = autocmd.NAMES[e] or {}
    array.each(pattern, function (p)
      autocmd.NAMES[e][p] = autocmd.NAMES[e][p] or {}
      autocmd.NAMES[e][p] = self
      autocmd.NAMES[hash(e, p)] = self
    end)
  end)
end

function autocmd:init(event, pattern, opts)
  opts = isa('table', opts or {})
  opts.group = group or 'doom_default'
  self.event = array.tolist(event)
  self.pattern = array.tolist(pattern)
  self.opts = opts
  self.buffers = {}
  self.callbacks = {}
  self.group = opts.group
  opts.pattern = self.pattern
  local callback = opts.callback

  opts.callback = function (opts)
    self.buffers[vim.fn.bufnr()] = true 
    array.each(dict.values(self.callbacks), function (cb)
      return cb(opts)
    end)
  end

  if opts.group then vim.api.nvim_create_augroup(opts.group, {clear=false}) end
  self.id = vim.api.nvim_create_autocmd(self.event, opts)
  make_state(self.event, self.pattern, self)
  autocmd.IDS[self.id] = self
end

function autocmd:register(name, callback)
  if is_a(name, 'table') then
    dict.each(name, function (key, cb)
      self.callbacks[key] = cb
    end)
  else
    self.callbacks[name] = callback
  end
end

function autocmd:disable()
  if not self.id then return false end
  vim.api.nvim_del_autocmd(self.id)
  self.id = false
end

function autocmd:exists(bufnr)
  return self.buffers[bufnr] ~= false
end

function autocmd.get(event, pattern)
  event = array.tolist(event)
  pattern = array.tolist(pattern)
  return autocmd.NAMES[hash(event, pattern)]
end

function autocmd.create(event, pattern)
  local exists = autocmd.get(event, pattern)
  if not exists then
    exists = autocmd(event, pattern)
  end
  return exists
end

local au = autocmd({'BufRead', 'BufEnter'}, '*.rb')
au:register {
  hello = function ()
    print('hello')
  end,
  world = function ()
    print('world')
  end
}

pp(autocmd.get({'BufRead', 'BufEnter'}, '*.rb'))
