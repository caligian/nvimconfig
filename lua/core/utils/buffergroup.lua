require "core.utils.au"
require "core.utils.kbd"

if not BufferGroup then
  BufferGroup = class "BufferGroup"
  BufferGroup.buffergroups = {}
  BufferGroup._buffers = {}
end

function BufferGroup:exclude_buffer(bufnr)
  self.exclude[bufnr] = true
  self.buffers[bufnr] = nil
  dict.unset(BufferGroup._buffers, { bufnr, self.name })
end

function BufferGroup.telescope_list_groups(bufnr)
  if not buffer.exists(bufnr) then
    return
  end

  local groups = BufferGroup._buffers[bufnr]
  if not groups then
    return
  end

  ls = keys(groups)
  if #ls == 0 then
    tostderr(
      "no buffergroups exist for " .. buffer.name(bufnr)
    )
    return
  end

  local usegroups = {}
  list.each(ls, function(x)
    usegroups[x] = BufferGroup.buffergroups[x]
  end)

  return {
    results = ls,
    entry_maker = function(x)
      local event = sprintf(
        "{%s}",
        join(tolist(usegroups[x].event), " ")
      )
      local pattern = sprintf(
        "{%s}",
        join(tolist(usegroups[x].pattern), " ")
      )
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
      x = buffer.name(x)
      local event =
        sprintf("{%s}", join(tolist(self.event), " "))
      local pattern =
        sprintf("{%s}", join(tolist(self.pattern), " "))
      return {
        display = x:gsub(os.getenv "HOME", "~")
          .. " "
          .. event
          .. " "
          .. pattern,
        value = bufnr,
        ordinal = x,
      }
    end,
  }
end

function BufferGroup.create_picker(self)
  local ls

  if isnumber(self) then
    ls = BufferGroup.telescope_list_groups(self)
    if not ls then
      return
    elseif #ls.results == 1 then
      return BufferGroup.create_picker(
        BufferGroup.buffergroups[ls.results[1]]
      )
    end

    local T = require "core.utils.telescope"()
    return T:create_picker(ls, function(group)
      if #group == 0 then
        return
      end

      group = group[1]
      BufferGroup.run_picker(
        BufferGroup.buffergroups[group.value]
      )
    end, {
      prompt_title = "BufferGroups for buffer "
        .. buffer.name(self):gsub(os.getenv "HOME", "~"),
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

      buffer.open(bufs[1].value)
    end,
    {
      "n",
      "x",
      function(bufs)
        list.each(bufs, function(buf)
          print(
            "excluding buffer " .. buffer.name(buf.value)
          )
          self:exclude_buffer(buf.value)
        end)
      end,
    },
  }, { prompt_title = "Buffers in " .. self.name })
end

function BufferGroup:run_picker()
  local picker = BufferGroup.create_picker(self)
  if picker then
    picker:find()
  end
end

function BufferGroup.fromdict(specs)
  local out = {}
  for key, value in pairs(specs) do
    assertisa(value, function(x)
      return islist(x) and #x == 2
    end)
    out[key] = BufferGroup(key, unpack(value))
  end

  return out
end

function BufferGroup:init(name, event, pattern, opts)
  if BufferGroup.buffergroups[name] then
    return BufferGroup.buffergroups[name]
  end

  opts = opts or {}
  local exclude = opts.exclude or {}
  self.event = event
  self.pattern = pattern
  self.exclude = exclude
  self.name = name
  self.buffers = {}
  self.au = Autocmd.map(event, {
    name = self.name,
    group = "BufferGroup",
    pattern = self.pattern,
    callback = function(o)
      local buf = o.buf
      if not self.exclude[buf] then
        self.buffers[buf] = true
        dict.set(BufferGroup._buffers, { buf, name }, true)
      end
    end,
  })

  BufferGroup.buffergroups[self.name] = self
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

    if config and istable(config) then
      dict.merge(specs, config)
    end
  end

  if usersrc then
    local config = loadfile(usersrc)
    config = config and config()

    if config and istable(config) then
      dict.merge(specs, config)
    end
  end

  if size(specs) > 0 then
    return BufferGroup.fromdict(specs)
  end
end

function BufferGroup.require()
  local specs = {}

  if req2path "core.defaults.buffergroup" then
    local config = requirex "core.defaults.buffergroup"
    if config and istable(config) then
      dict.merge(specs, config)
    end
  end

  if req2path "user.buffergroup" then
    local config = requirex "user.buffergroup"
    if config and istable(config) then
      dict.merge(specs, config)
    end
  end

  if size(specs) > 0 then
    return BufferGroup.fromdict(specs)
  end
end

function BufferGroup.main()
  BufferGroup.require()
  Kbd.map("n", "<leader>.", function()
    BufferGroup.run_picker(buffer.current())
  end, "show buffergroups")
end
