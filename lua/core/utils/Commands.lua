Command = struct("Command", { "name", "opts", "bufnr", "callback", "input_args", "keymap" })
Command.commands = {}

local create = vim.api.nvim_create_user_command
local bufcreate = vim.api.nvim_buf_create_user_command
local del = vim.api.nvim_del_user_command
local bufdel = vim.api.nvim_buf_del_user_command

function Command.init_before(name, callback, opts)
    opts = copy(opts or {})
    local bufnr = opts.bufnr
    local keymap = opts.keymap
    local input_args = opts.input_args
    opts.bufnr = nil
    opts.keymap = nil
    opts.input_args = nil

    return { name = name, bufnr = bufnr, opts = opts, callback = callback, keymap = keymap, input_args = input_args }
end

function Command.init(self)
    if self.bufnr then
        bufcreate(self.bufnr, self.name, self.callback, self.opts)
    else
        create(self.name, self.callback, self.opts)
    end

    if self.keymap then
        local mode, ks, opts = unpack(self.keymap)
        opts = opts or {}
        opts.name = self.name
        local function callback()
            if is_callable(self.callback) then
                if self.input_args then
                    local out = input(self.input_args)
                    self.callback(out)
                else
                    local userint = input { args = { sprintf "args for %s" } }
                    self.callback(userint.args)
                end
            elseif is_string(self.callback) then
                local userint = input { args = { sprintf("args for %s", self.name) } }
                vim.cmd(self.callback .. ' ' .. userint.args)
            end
        end

        self.keymap = kbd.map(mode, ks, callback, opts)
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

--------------------------------------------------
CommandGroup = struct("CommandGroup", { "name", "defaults", "commands" })

function CommandGroup.init_before(name, defaults)
    return { name = name, defaults = defaults or {}, commands = {} }
end

function CommandGroup.set(self, name, callback, opts)
    opts = opts or {}

    if self.defaults then
        opts = merge_(opts, self.defaults)
    end

    name = self.name .. name:gsub("^[a-z]", string.upper)
    self.commands[name] = Command(name, callback, opts)

    return self.commands[name]
end

function CommandGroup.remove(self, name)
    local exists = self.commands[name]
    if not exists then
        return
    else
        local cmd = self.commands[name]
        self.commands[name] = nil

        return Command.delete(cmd)
    end
end

--------------------------------------------------
function Command.map_group(name, specs)
    local out = CommandGroup(name)

end
