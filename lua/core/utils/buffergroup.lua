require "core.utils.au"
require "core.utils.kbd"
require "core.utils.telescope"

if not buffergroup then
  buffergroup = class "buffergroup"
  buffergroup.buffergroups = {}
  buffergroup._buffers = {}
end

function buffergroup:exclude_buffer(bufnr)
  self.exclude[bufnr] = true
  self.buffers[bufnr] = nil
  dict.unset(buffergroup._buffers, { bufnr, self.name })
end

function buffergroup.telescope_list_groups(bufnr)
  if not buffer.exists(bufnr) then
    return
  end

  local groups = buffergroup._buffers[bufnr]
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
    usegroups[x] = buffergroup.buffergroups[x]
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

function buffergroup:telescope_list_buffers()
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

function buffergroup.create_picker(self)
  local ls

  if isnumber(self) then
    ls = buffergroup.telescope_list_groups(self)
    if not ls then
      return
    elseif #ls.results == 1 then
      return buffergroup.create_picker(
        buffergroup.buffergroups[ls.results[1]]
      )
    end

    local tscope = load_telescope()
    return tscope:create_picker(ls, function(group)
      if #group == 0 then
        return
      end

      group = group[1]
      buffergroup.run_picker(
        buffergroup.buffergroups[group.value]
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

  local tscope = load_telescope()
  return tscope:create_picker(ls, {
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

function buffergroup:run_picker()
  local picker = buffergroup.create_picker(self)
  if picker then
    picker:find()
  end
end

function buffergroup.fromdict(specs)
  local out = {}
  for key, value in pairs(specs) do
    assertisa(value, function(x)
      return islist(x) and #x == 2
    end)
    out[key] = buffergroup(key, unpack(value))
  end

  return out
end

function buffergroup:init(name, event, pattern, opts)
  if buffergroup.buffergroups[name] then
    return buffergroup.buffergroups[name]
  end

  opts = opts or {}
  local exclude = opts.exclude or {}
  self.event = event
  self.pattern = pattern
  self.exclude = exclude
  self.name = name
  self.buffers = {}
  self.au = au.map(event, {
    name = "buffergroup." .. self.name,
    group = "MyBufferGroups",
    pattern = self.pattern,
    callback = function(o)
      local buf = o.buf
      if not self.exclude[buf] then
        self.buffers[buf] = true
        dict.set(buffergroup._buffers, { buf, name }, true)
      end
    end,
  })

  buffergroup.buffergroups[self.name] = self
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

function buffergroup.loadfile()
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
    return buffergroup.fromdict(specs)
  end
end

function buffergroup.require()
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
    return buffergroup.fromdict(specs)
  end
end

function buffergroup.main()
  buffergroup.require()

  kbd.map("n", "<leader>.", function()
    buffergroup.run_picker(buffer.current())
  end, "show buffergroups")
end
