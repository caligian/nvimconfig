--- Autocommand creater for this framework
--
class("Autocmd")

A = Autocmd
A.ids = A.ids or {}
A.defaults = A.defaults or {}
A.groups = A.groups or {}

function Autocmd._init(self, event, opts)
  return log_pcall(function()
    validate({
      event = { is { "s", "t" }, event },
      options = {
        {
          callback = is { "f", "s" },
          pattern = is { "s", "t" },
        },
        opts,
      },
    })

    local augroup
    local group = copy(opts.group or {})
    local name = opts.name
    opts.name = nil
    if type(group) == "string" then
      augroup = vim.api.nvim_create_augroup(group)
    else
      group[1] = group[1] or "UserGlobal"
      group[2] = group[2] or {}
      augroup = vim.api.nvim_create_augroup(unpack(group))
      group = group[1]
    end

    local callback = opts.callback
    opts.callback = function()
      if opts.once then
        if is_a.s(callback) then
          vim.cmd(callback)
        else
          callback()
        end
      else
        if is_a.s(callback) then
          vim.cmd(callback)
        else
          callback()
        end
      end
    end

    local id = autocmd(event, opts)
    self.id = id
    self.gid = augroup
    self.group = group
    self.event = event
    self.enabled = false
    self.opts = opts
    self.opts.name = name

    for key, value in pairs(opts) do
      self[key] = value
    end

    update(Autocmd.ids, id, self)
    update(Autocmd.groups, { augroup, id }, self)

    if name then
      Autocmd.defaults[name] = self
    end
    self.name = name

    return self
  end)
end

function Autocmd.disable(self)
  return log_pcall(function ()
    if not self.enabled then
      return
    end
    vim.api.nvim_del_autocmd(self.id)
    self.enabled = false

    return self
  end)
end

function Autocmd.delete(self)
  return log_pcall(function ()
    self:disable()

    if self.name then
      Autocmd.defaults[self.name] = nil
    end

    Autocmd.ids[self.id] = nil
    Autocmd.groups[self.group][self.id] = nil

    return self
  end)
end

function Autocmd.replace(self, opts)
  return log_pcall(function ()
    self:delete()

    opts = self.opts or opts
    opts.callback = callback

    return Autocmd(self.event, opts)
  end)
end
