local dispatch = Plugin.get "dispatch"
dispatch.methods = {}

function dispatch.methods.get_command(action, bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    local name = buffer.name(bufnr)
    local cmd = Filetype.get(vim.bo.filetype, action)

    if not cmd then
        return nil, 'no command found for ' .. bufnr
    elseif is_callable(cmd) then
        cmd = cmd(bufnr)
    elseif is_string(cmd) then
        if not cmd:match "%%%%" then
            cmd = cmd .. " " .. name
        else
            cmd = cmd:gsub("%%%%", name)
        end
    else
        pp("no command specified for filetype " .. cmd)
        return
    end

    return ("Dispatch " .. cmd)
end

function dispatch.methods.get_compiler(bufnr)
    return dispatch.methods.get_command("compile", bufnr)
end

function dispatch.methods.get_build(bufnr)
    return dispatch.methods.get_command("build", bufnr)
end

function dispatch.methods.get_test(bufnr)
    return dispatch.methods.get_command("test", bufnr)
end

function dispatch.methods.run(action, bufnr)
    bufnr = bufnr or buffer.bufnr()
    local cmd = dispatch.methods.get_command(action, bufnr)
    if not cmd then
        return
    end

    local base = path.dirname(buffer.name(bufnr))
    local currentdir = path.currentdir()

    vim.cmd(":chdir " .. base)
    vim.cmd(cmd)
    vim.cmd(":chdir " .. currentdir)
end

function dispatch.methods.build(bufnr)
    dispatch.run("build", bufnr)
end

function dispatch.methods.test(bufnr)
    dispatch.run("test", bufnr)
end

function dispatch.methods.compile(bufnr)
    dispatch.run("compile", bufnr)
end

dispatch.mappings = {
    opts = { noremap = true, leader = true },
    build = {
        "cb",
        dispatch.methods.build,
        "n",
        { noremap = true, desc = "Build file" },
    },
    open_qflist = {
        "cq",
        ":Copen<CR>",
        "n",
        { desc = "Open qflist", noremap = true },
    },
    test = {
        "ct",
        dispatch.methods.test,
        "n",
        { noremap = true, desc = "Test file" },
    },
    compile = {
        "cc",
        dispatch.methods.compile,
        "n",
        { noremap = true, desc = "Compile file" },
    },
}

return dispatch
