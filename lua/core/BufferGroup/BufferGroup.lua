BufferGroup = BufferGroup or class "BufferGroup"
BufferGroup.STATE = BufferGroup.STATE or {}
local state = BufferGroup.STATE
local string_or_table = is { "table", "string" }

BufferGroup.NotEnabledException = exception "group has not been enabled yet"
BufferGroup.NonExistentException = exception "group does not exist"
BufferGroup.NonExistentBufferException =
  exception "buffer does not exist in group"
BufferGroup.InvalidBufferException = exception "valid buffer expected"

local function bufferdict()
  return setmetatable({}, {
    __index = function(self, key) return rawget(self, buffer.bufnr(key)) end,
    __newindex = function(self, key, value)
      rawset(self, buffer.bufnr(key), true)
    end,
  })
end

function BufferGroup:init(name, event, pattern, pool)
  validate {
    name = { "string", name },
    pattern = { string_or_table, pattern },
    opt_event = { string_or_table, event },
    opt_pool = { "string", pool },
  }

  self.name = name
  self.event = array.toarray(event or "BufEnter")
  self.pattern = array.toarray(pattern)
  self.pool = pool or "default"
  self.augroup = false
  self.buffers = bufferdict()
  self.enabled = false
  self.exclude = bufferdict()

  dict.update(state, { self.pool, self.name }, self)
end

function BufferGroup:has(buf) return self.buffers[buf] end

function BufferGroup:addpattern(pat)
  self.pattern[#self.pattern + 1] = pat
  return self.pattern
end

function BufferGroup:addevent(event)
  self.event[#self.event + 1] = event
  return self.event
end

function BufferGroup:excluded(bufnr) return self.exclude[buffer.bufnr(bufnr)] end

function BufferGroup:isempty() return #dict.keys(self.buffers) == 0 end

function BufferGroup:isvalid(bufnr)
  if self:excluded(bufnr) then return end

  local name = buffer.name(buffer.bufnr(bufnr))

  return array.all(
    array.filter(self.pattern, function(pat) return name:match(pat) end)
  )
end

function BufferGroup:add(bufnr)
  if not self:isvalid(bufnr) then
    return
  else
    self.buffers[bufnr] = true
    return bufnr
  end
end

function BufferGroup:remove(bufnr)
  bufnr = buffer.bufnr(bufnr)
  if not self.buffers[bufnr] then return end

  self.exclude[bufnr] = true
  self.buffers[bufnr] = nil

  return bufnr
end

function BufferGroup:disable()
  if not self.enabled then return end
  if not self.augroup then return end

  self.augroup:disable()
  self.enabled = false
  return true
end

function BufferGroup:hook(callback)
  if not self.enabled then BufferGroup.NotEnabledException:throw(self) end

  self.augroup:add("BufEnter", {
    pattern = "*",
    callback = function(au)
      if not self:isvalid(au.buf) then return end
      callback(au)
    end,
  })

  return hook
end

function BufferGroup:enable(clear)
  if self.enabled then return end

  local augroup = self.augroup
  if clear and augroup then augroup:disable() end
  local group_name = "BufferGroup" .. self.name

  augroup = Augroup(group_name)
  augroup:add(self.event, {
    pattern = "*",
    callback = function(au)
      local bufnr = au.buf

      if self:excluded(bufnr) or not self:add(bufnr) then return end

      local state = buffer.getvar(bufnr, "BufferGroup") or {}
      dict.update(
        state,
        { self.pool, self.name },
        { group = self.name, pool = self.pool }
      )
      buffer.setvar(bufnr, "BufferGroup", state)
    end,
    desc = "Buffer group: " .. group_name,
  })

  self.enabled = true
end

function BufferGroup:disallow(buf)
  if self:excluded(buf) then
    return
  else
    buf = buffer.bufnr(buf)
    self.exclude[buf] = true
    return buf
  end
end

function BufferGroup:allow(buf)
  if not self:excluded(buf) then return end

  self.exclude[buffer.bufnr(buf)] = nil
  return true
end

function BufferGroup:list()
  if self:isempty() then return end
  return array.map(
    dict.keys(self.buffers),
    function(bufnr) return buffer.name(bufnr) end
  )
end

function BufferGroup:getpicker(remover)
  local buffers = self:list()
  if not buffers then return end

  local T = utils.telescope.load()

  local function default_action(bufnr)
    local sel = T.selected(bufnr)
    if remover then
      array.each(sel, function(buf) self:remove(buf[1]) end)
    elseif #sel > 1 then
      error "cannot use multiselect to open buffer"
    else
      vim.cmd(":b " .. sel[1][1])
    end
  end

  local function remove_buffer(bufnr)
    array.each(T.selected(bufnr), function(buffer) self:remove(buffer[1]) end)
  end

  return T.create_picker(buffers, {
    default_action,
    { "n", "x", remove_buffer },
    { "i", "<C-d>", remove_buffer },
  }, {
    prompt_title = sprintf("%s :: %s", self.pool, self.name),
  })
end

function BufferGroup.exists(pool, name, bufnr)
  pool = pool or "default"

  if not bufnr then
    return dict.get(BufferGroup.STATE, { pool, name })
  else
    local group = dict.get(BufferGroup.STATE, { pool, name })
    if not group then return end
    return group:has(bufnr)
  end
end

function BufferGroup.assertexists(pool, name, bufnr)
  pool = pool or "default"
  local exists = BufferGroup.exists(pool, name)

  if not exists then
    BufferGroup.NonExistentException:throw { pool = pool, name = name }
  end

  if bufnr then
    if not exists:has(bufnr) then
      BufferGroup.NonExistentBufferException:throw {
        pool = pool,
        name = name,
        bufnr = bufnr,
      }
    else
      return bufnr
    end
  end

  return exists
end

function BufferGroup.create(pool, name, event, pattern)
  local exists = BufferGroup.exists(pool, name)
  if not exists then return BufferGroup(name, event, pattern, pool) end
  return exists
end

function BufferGroup.getbufinfo(bufnr)
  bufnr = bufnr or buffer.bufnr()
  return buffer.getvar(bufnr, "BufferGroup")
end

function BufferGroup.getstatusline(bufnr)
  local state = BufferGroup.getbufinfo(bufnr)
  if not state then return end
  return ("<" .. state.pool .. "." .. state.name .. ">")
end

function BufferGroup:delete()
  if not self.enabled then return end

  self:disable()
  BufferGroup.STATE[self.pool][self.name] = nil

  return self
end

function BufferGroup.getmainpicker(remover)
  local T = utils.telescope.load()
  local pools = dict.keys(BufferGroup.STATE)
  if #pools == 0 then return end

  local function remove_pool(bufnr)
    local sel = T.selected(bufnr)
    array.each(sel, function(pool)
      dict.each(
        BufferGroup.STATE[pool[1]],
        function(name, obj) obj:delete() end
      )

      BufferGroup.STATE[pool[1]] = nil
    end)
  end

  local function showgroup(bufnr)
    local pool = T.selected(bufnr)[1][1]
    local groups = BufferGroup.STATE[pool]

    if dict.isblank(groups) then return end

    T.create_picker(dict.keys(groups), {
      function(bufnr)
        local sel = T.selected(bufnr)[1][1]
        local obj = BufferGroup.exists(pool, sel)
        local picker = obj:getpicker()
        if picker then picker:find() end
      end,
      {
        "n",
        "x",
        function(bufnr)
          local sel = T.selected(bufnr)
          array.each(sel, function(x)
            local group = BufferGroup.exists(pool, x[1])
            group:delete()
          end)
        end,
      },
    }, {
      prompt_title = "Buffer group pool :: " .. pool,
    }):find()
  end

  local function default_action(bufnr)
    if remover then
      remove_pool(bufnr)
      return
    end

    showgroup(bufnr)
  end

  local function add_group(bufnr)
    local pool = T.selected(bufnr)[1][1]
    local userint = input {
      { "name", "Buffer group name" },
      { "pattern", "Buffer matching pattern" },
    }
    BufferGroup(userint.name, "BufEnter", userint.pattern, pool)
  end

  return T.create_picker(pools, {
    default_action,
    { "n", "x", remove_pool },
    { "n", "a", add_group },
  }, {
    prompt_title = "Buffer group pools",
  })
end

function BufferGroup.getbufpicker(bufnr)
  local T = utils.telescope.load()
  bufnr = bufnr or buffer.bufnr()
  local state = buffer.getvar(bufnr, "BufferGroup")
  if not state then return end
  local pools = dict.keys(state)
  local n = #pools

  if n == 0 then return end

  local function single(pool_name)
    local groups = dict.keys(state[pool_name])

    if #groups == 1 then
      local group = BufferGroup.STATE[pool_name][groups[1]]
      local picker = group:getpicker()
      if not picker then return end
      picker:find()

      return
    end

    return T.create_picker(groups, function(bufnr)
      local sel = T.selected(bufnr)[1][1]
      local group = BufferGroup.exists(pool_name, sel)
      local picker = group:getpicker()
      if picker then picker:find() end
    end, { prompt_title = "Buffer picker for group pools" })
  end

  if n == 1 then return single(pools[1]) end

  return T.create_picker(pools, function(bufnr)
    local sel = T.selected(bufnr)[1][1]
    local picker = single(sel)
    if picker then picker:find() end
  end)
end

function BufferGroup.loaddefaults()
  dict.each(BufferGroup.defaults, function(pool, groupspec)
    dict.each(groupspec, function(name, spec)
      if is_a.string(spec) then
        BufferGroup(name, "BufEnter", spec, pool):enable()
      elseif is_a.table(spec) then
        local args = { unpack(spec), pool }
        BufferGroup(unpack(args)):enable()
      end
    end)
  end)
end

function BufferGroup.runmainpicker(remover)
  local picker = BufferGroup.getmainpicker(remover, force)
  if picker then
    picker:find()
    return true
  end
end

function BufferGroup.runbufpicker(remover)
  local picker = BufferGroup.getbufpicker(remover)
  if picker then
    picker:find()
    return true
  end
end

--- Available mappings
-- BufferGroup.runbufpicker
-- BufferGroup.runmainpicker
function BufferGroup.setmappings() K.bind(BufferGroup.mappings) end

--- Return buffer state
function BufferGroup.getbuffer(bufnr)
  return buffer.getvar(bufnr, 'BufferGroup')
end

function BufferGroup.listpools(bufnr)
  if not bufnr then
    local ks = dict.keys(BufferGroup.STATE)
    if #ks == 0 then return end

    return ks
  end

  local state = BufferGroup.getbuffer(bufnr)
  if not state then return end

  local ks = dict.keys(state)
  if ks == 0 then return end

  return ks
end

function BufferGroup.disablepool(pool)
  local pool = BufferGroup.STATE[pool]
  if not pool then return end

  array.each(dict.values(pool), function (obj)
    obj:disable()
  end)

  return pool
end

function BufferGroup.removepool(pool)
  local groups = BufferGroup.STATE[pool]
  if not groups then return end

  array.each(dict.values(groups), function (obj)
    obj:disable()
  end)

  BufferGroup.STATE[pool] = nil

  return pool
end

return BufferGroup
