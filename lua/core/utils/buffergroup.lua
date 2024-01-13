require "core.utils.au"
require "core.utils.kbd"

if not BufferGroup then
  BufferGroup = class(
    "BufferGroup",
    { "loadfile", "require", "main", "from_dict", "telescope_list_groups_for_buffer", "telescope_list_groups" }
  )
end

function BufferGroup:reinclude_buffer(bufnr)
  if not Buffer.exists(bufnr) then
    return
  end

  self.buffers[bufnr] = true
  self.exclude[bufnr] = nil

  dict.set(user.buffers, { bufnr, "buffer_groups" }, self.name)

  return true
end

function BufferGroup:create_reinclude_buffers_picker()
  local excluded = keys(self.exclude)
  if #excluded == 0 then
    return
  end

  excluded = {
    results = excluded,
    entry_maker = function(obj)
      local name = Buffer.get_name(obj)
      return {
        display = name,
        value = tostring(obj),
        ordinal = name,
      }
    end,
  }

  user.telescope()
  local function default_action(bufnr)
    list.each(user.telescope:selected(bufnr, true), function(obj)
      self:reinclude_buffer(tonumber(obj.value))
    end)
  end

  return user.telescope:create_picker(
    excluded,
    { default_action },
    { prompt_title = "reinclude buffers for " .. self.name }
  )
end

function BufferGroup:reinclude_buffers()
  dict.each(self.exclude, function(bufnr, _)
    self:reinclude_buffers(bufnr)
  end)
end

function BufferGroup:exclude_buffer(bufnr)
  self.exclude[bufnr] = true
  self.buffers[bufnr] = nil

  dict.unset(user.buffers, { bufnr, "buffer_groups", self.name })
end

function BufferGroup.telescope_list_groups()
  groups = keys(user.buffer_groups)
  if #groups == 0 then
    return
  end

  local ls = groups
  if #ls == 0 then
    is_stderr("no buffergroups exist for " .. Buffer.get_name(bufnr))
    return
  end

  local usegroups = {}
  list.each(ls, function(x)
    usegroups[x] = user.buffer_groups[x]
  end)

  return {
    results = ls,
    entry_maker = function(x)
      local event = sprintf("{%s}", join(totable(usegroups[x].event), " "))
      local pattern = sprintf("{%s}", join(totable(usegroups[x].pattern), " "))
      return {
        display = x .. " " .. event .. " " .. pattern,
        value = x,
        ordinal = x,
      }
    end,
  }
end

function BufferGroup.telescope_list_groups_for_buffer(bufnr)
  if not Buffer.exists(bufnr) then
    return
  elseif not user.buffers[bufnr] or not user.buffers[bufnr].buffer_groups then
    return
  end

  groups = keys(user.buffers[bufnr].buffer_groups)
  if #groups == 0 then
    return
  end

  local ls = groups
  if #ls == 0 then
    is_stderr("no buffergroups exist for " .. Buffer.get_name(bufnr))
    return
  end

  local usegroups = {}
  list.each(ls, function(x)
    usegroups[x] = user.buffer_groups[x]
  end)

  return {
    results = ls,
    entry_maker = function(x)
      local event = sprintf("{%s}", join(totable(usegroups[x].event), " "))
      local pattern = sprintf("{%s}", join(totable(usegroups[x].pattern), " "))
      return {
        display = x .. " " .. event .. " " .. pattern,
        value = x,
        ordinal = x,
      }
    end,
  }
end

function BufferGroup:telescope_list_buffers()
  local ls = keys(self.buffers)
  if #ls == 0 then
    return
  end

  return {
    results = ls,
    entry_maker = function(x)
      local bufnr = x
      x = Buffer.get_name(x)
      local event = sprintf("{%s}", join(totable(self.event), " "))
      local pattern = sprintf("{%s}", join(totable(self.pattern), " "))
      return {
        display = x:gsub(os.getenv "HOME", "~") .. " " .. event .. " " .. pattern,
        value = bufnr,
        ordinal = x,
      }
    end,
  }
end

local function create_buffer_picker(self)
  local ls = BufferGroup.telescope_list_buffers(self)

  if not ls then
    return
  end

  user.telescope()

  local mod = {
    exclude = function(prompt_bufnr)
      local bufs = user.telescope:selected(prompt_bufnr, true)
      list.each(bufs, function(buf)
        self:exclude_buffer(buf.value)
      end)
    end,
  }

  local T = user.telescope()
  return T:create_picker(ls, {
    function(prompt_bufnr)
      local buf = user.telescope:selected(prompt_bufnr)
      Buffer.open(buf.value)
    end,
    {
      "n",
      "x",
      mod.exclude,
    },
  }, { prompt_title = "Buffers in " .. self.name })
end

--- @param self number|BufferGroup
function BufferGroup:create_buffer_picker()
  local ls

  if is_number(self) then
    ls = BufferGroup.telescope_list_groups_for_buffer(self)

    if not ls then
      return
    elseif #ls.results == 1 then
      return create_buffer_picker(user.buffer_groups[ls.results[1]])
    end

    user.telescope()

    local mod = {
      reinclude = function(prompt_bufnr)
        local group = user.telescope:selected(prompt_bufnr)
        group = user.buffer_groups[group.value]
        local picker = group:create_reinclude_buffers_picker()
        if picker then
          picker:find()
        end
      end,
    }

    return user.telescope:create_picker(ls, {
      function(prompt_bufnr)
        local group = user.telescope:selected(prompt_bufnr)
        user.buffer_groups[group.value]:run_buffer_picker()
      end,
      { "n", "X", mod.reinclude },
    }, {
      prompt_title = "BufferGroups for buffer " .. Buffer.get_name(self):gsub(os.getenv "HOME", "~"),
    })
  end

  return create_buffer_picker(self)
end

function BufferGroup:run_reinclude_buffers_picker()
  local picker = self:create_reinclude_buffers_picker()
  if picker then
    picker:find()
    return true
  end

  return
end

function BufferGroup.run_main_picker()
  local picker = BufferGroup.create_main_picker()
  if not picker then
    return
  end

  picker:find()
  return true
end

function BufferGroup.create_main_picker()
  local groups = BufferGroup.telescope_list_groups()
  if not groups then
    return
  end

  user.telescope()

  local mod = {
    reinclude = function(prompt_bufnr)
      local group = user.telescope:selected(prompt_bufnr)
      group = user.buffer_groups[group.value]
      group:run_reinclude_buffers_picker()

      if not group:create_reinclude_buffers_picker() then
        print "no buffers excluded yet"
      end
    end,
    delete = function(prompt_bufnr)
      list.each(user.telescope:selected(prompt_bufnr, true), function(group)
        group = user.buffer_groups[group.value]
        group:delete()
      end)
    end,
  }

  return user.telescope:create_picker(groups, {
    function(prompt_bufnr)
      local group = user.telescope:selected(prompt_bufnr)
      group = user.buffer_groups[group.value]
      group:run_buffer_picker()
    end,
    { "n", "X", mod.reinclude },
    { "n", "x", mod.delete },
  }, { prompt_title = "BufferGroups" })
end

function BufferGroup.run_buffer_picker(self)
  local picker = BufferGroup.create_buffer_picker(self)

  if picker then
    picker:find()
  end
end

function BufferGroup.from_dict(specs)
  local out = {}
  for key, value in pairs(specs) do
    assert_is_a(value, function(x)
      return is_list(x) and #x == 2
    end)
    out[key] = BufferGroup(key, unpack(value))
  end

  return out
end

function BufferGroup:delete()
  self:disable()
  user.buffer_groups[self.name] = nil

  dict.each(user.buffers, function(bufnr, state)
    state.buffer_groups[self.name] = nil
  end)
end

function BufferGroup:is_active()
  return self.autocmd and self.autocmd:exists() or false
end

function BufferGroup:disable()
  if not self.autocmd then
    return
  end

  self.autocmd:disable()
  self.autocmd = nil

  return self
end

function BufferGroup:init(name, event, pattern, opts)
  local already = user.buffer_groups[name]
  if already and already:is_active() then
    return already
  end

  opts = opts or {}
  local exclude = opts.exclude or {}
  self.event = event
  self.pattern = pattern
  self.exclude = exclude
  self.name = name
  self.buffers = {}
  self.autocmd = Autocmd(event, {
    name = self.name,
    group = "BufferGroup",
    pattern = self.pattern,
    callback = function(o)
      local buf = o.buf
      if not self.exclude[buf] then
        self.buffers[buf] = true
        dict.set(user.buffers, { buf, "buffer_groups", name }, true)
      end
    end,
  })

  user.buffer_groups[self.name] = self
  self.telescope = setmetatable({}, {
    __index = function(here, key)
      if T[key] then
        return function(...)
          return T[key](self, ...)
        end
      end
    end,
  })

  return self
end

function BufferGroup.loadfile()
  local specs = {}
  local src = req2path "core.defaults.buffergroup"
  local usersrc = req2path "user.buffergroup"

  if src then
    local config = loadfile(src)
    config = config and config()

    if config and is_table(config) then
      dict.merge(specs, { config })
    end
  end

  if usersrc then
    local config = loadfile(usersrc)
    config = config and config()

    if config and is_table(config) then
      dict.merge(specs, { config })
    end
  end

  if size(specs) > 0 then
    return BufferGroup.from_dict(specs)
  end
end

function BufferGroup.require()
  local specs = {}

  if req2path "core.defaults.buffergroup" then
    local config = requirex "core.defaults.buffergroup"
    if config and is_table(config) then
      dict.merge(specs, { config })
    end
  end

  if req2path "user.buffergroup" then
    local config = requirex "user.buffergroup"
    if config and is_table(config) then
      dict.merge(specs, { config })
    end
  end

  if size(specs) > 0 then
    return BufferGroup.from_dict(specs)
  end
end

function BufferGroup.main()
  BufferGroup.require()

  Kbd.map("n", "<leader>>", function()
    BufferGroup.run_main_picker()
  end, "show buffergroups")

  Kbd.map("n", "<leader>.", function()
    BufferGroup.run_buffer_picker(Buffer.current())
  end, "show buffergroups for buffer")
end
