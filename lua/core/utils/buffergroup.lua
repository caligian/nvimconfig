require "core.utils.au"
require "core.utils.kbd"

if not BufferGroup then
  BufferGroup = class("BufferGroup", { "loadfile", "require", "main", "from_dict", "telescope_list_groups" })
  user.buffer_groups = {}
  user.buffers = user.buffers or {}
end

function BufferGroup:exclude_buffer(bufnr)
  self.exclude[bufnr] = true
  self.buffers[bufnr] = nil

  dict.unset(user.buffers, { bufnr, "buffer_groups", self.name })
end

function BufferGroup.telescope_list_groups(bufnr)
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
      local event = sprintf("{%s}", join(to_list(usegroups[x].event), " "))
      local pattern = sprintf("{%s}", join(to_list(usegroups[x].pattern), " "))
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
      local event = sprintf("{%s}", join(to_list(self.event), " "))
      local pattern = sprintf("{%s}", join(to_list(self.pattern), " "))
      return {
        display = x:gsub(os.getenv "HOME", "~") .. " " .. event .. " " .. pattern,
        value = bufnr,
        ordinal = x,
      }
    end,
  }
end

function BufferGroup.create_picker(self)
  local ls

  if is_number(self) then
    ls = BufferGroup.telescope_list_groups(self)
    if not ls then
      return
    elseif #ls.results == 1 then
      return BufferGroup.create_picker(user.buffer_groups[ls.results[1]])
    end

    local T = require "core.utils.telescope"()
    return T:create_picker(ls, function(group)
      if #group == 0 then
        return
      end

      group = group[1]
      BufferGroup.run_picker(user.buffer_groups[group.value])
    end, {
      prompt_title = "BufferGroups for buffer " .. Buffer.get_name(self):gsub(os.getenv "HOME", "~"),
    })
  end

  ls = self:telescope_list_buffers()
  if not ls then
    return
  end

  local T = require "core.utils.telescope"()
  return T:create_picker(ls, {
    function(bufs)
      if #bufs == 0 then
        return
      end

      Buffer.open(bufs[1].value)
    end,
    {
      "n",
      "x",
      function(bufs)
        list.each(bufs, function(buf)
          print("excluding buffer " .. Buffer.get_name(buf.value))
          self:exclude_buffer(buf.value)
        end)
      end,
    },
  }, { prompt_title = "Buffers in " .. self.name })
end

function BufferGroup.run_picker(self)
  local picker = BufferGroup.create_picker(self)

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

function BufferGroup:init(name, event, pattern, opts)
  if user.buffer_groups[name] then
    return user.buffer_groups[name]
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
  Kbd.map("n", "<leader>.", function()
    BufferGroup.run_picker(Buffer.current())
  end, "show buffergroups")
end
