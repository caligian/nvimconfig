local dispatch = plugin.get "dispatch"

function dispatch.getcommand(action, bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    local name = buffer.name(bufnr)
    local cmd = Filetype.get(vim.bo.filetype, action)

    if is_callable(cmd) then
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

function dispatch.getcompiler(bufnr) return getcommand("compile", bufnr) end

function dispatch.getbuild(bufnr) return getcommand("build", bufnr) end

function dispatch.gettest(bufnr) return getcommand("test", bufnr) end

function dispatch.run(action, bufnr)
    bufnr = bufnr or buffer.bufnr()
    local cmd = getcommand(action, bufnr)
    if not cmd then return end

    local base = path.dirname(buffer.name(bufnr))
    local currentdir = path.currentdir()

    vim.cmd(":chdir " .. base)
    vim.cmd(cmd)
    vim.cmd(":chdir " .. currentdir)
end

function dispatch.build(bufnr) run("build", bufnr) end

function dispatch.test(bufnr) run("test", bufnr) end

function dispatch.compile(bufnr) run("compile", bufnr) end

dispatch.mappings = {
    opts = { noremap = true, leader = true },
    build = {
        "cb",
        dispatch.build,
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
        dispatch.test,
        "n",
        { noremap = true, desc = "Test file" },
    },
    compile = {
        "cc",
        dispatch.compile,
        "n",
        { noremap = true, desc = "Compile file" },
    },
}


