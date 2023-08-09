Command = struct("Command", { "name", "opts", "bufnr", "callback" })
Command.commands = {}

local create = vim.api.nvim_create_user_command
local bufcreate = vim.api.nvim_buf_create_user_command
local del = vim.api.nvim_del_user_command
local bufdel = vim.api.nvim_buf_del_user_command

function Command.init_before(name, callback, opts)
    opts = copy(opts or {})
    local bufnr = opts.bufnr
    opts.bufnr = nil

    return { name = name, bufnr = bufnr, opts = opts, callback = callback }
end

function Command.init(self)
    if self.bufnr then
        bufcreate(self.bufnr, self.name, self.callback, self.opts)
    else
        create(self.name, self.callback, self.opts)
    end

    Command.commands[self.name] = self
    return self
end

function Command.delete(self)
    if self.bufnr then
        bufdel(self.bufnr, self.name)
    else
        del(self.name)
    end

    Command.commands[self.name] = nil
    return self
end

function Command.static_delete(name)
    local exists = Command.commands[name]
    if exists then
        return Command.delete(exists)
    end
end

function Command.map_group(name, specs)
    local out = {}

    dict.each(specs, function (spec_name, spec)
        out[name] = Command(name .. spec_name, unpack(spec))
    end)

    return out
end
