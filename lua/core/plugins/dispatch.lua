local plug = plugin.dispatch

local function getcommand(action, bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  local name = buffer.name(bufnr)
  local cmd = Filetype.get(vim.bo.filetype, action)

  if is_callable(cmd) then 
    cmd = cmd(bufnr) 
  elseif is_string(cmd) then
    if not cmd:match '%%%%' then
      cmd = cmd .. ' ' .. name
    else
      cmd = cmd:gsub('%%%%', name)
    end
  else
    pp('no command specified for filetype ' .. cmd)
    return
  end

  return ('Dispatch ' .. cmd)
end

local function getcompiler(bufnr)
  return getcommand('compile', bufnr)
end

local function getbuild(bufnr)
  return getcommand('build', bufnr)
end

local function gettest(bufnr)
  return getcommand('test', bufnr)
end

local function run(action, bufnr)
  bufnr = bufnr or buffer.bufnr()
  local cmd = getcommand(action, bufnr)
  if not cmd then return end

  local base = path.dirname(buffer.name(bufnr))
  local currentdir = path.currentdir()

  vim.cmd(':chdir ' .. base)
  vim.cmd(cmd)
  vim.cmd(':chdir ' .. currentdir)
end

local function build(bufnr)
  run('build', bufnr)
end

local function test(bufnr)
  run('test', bufnr)
end

local function compile(bufnr)
  run('compile', bufnr)
end

plug.methods = {
  getcommand = getcommand,
  getcompiler = getcompiler,
  getbuild = getbuild,
  gettest = gettest,
  run = run,
  compile = compile,
  build = build,
  test = test,
}

plug.kbd = {
  noremap = true,
  leader = true,
  {
    "cb",
    plug.methods.build,
    "n",
    { noremap = true, desc = "Build file" },
  },
  {
    "cq",
    ":Copen<CR>",
    "n",
    { desc = "Open qflist", noremap = true },
  },
  {
    "ct",
    plug.methods.test,
    "n",
    { noremap = true, desc = "Test file" },
  },
  {
    "cc",
    plug.methods.compile,
    "n",
    { noremap = true, desc = "Compile file" },
  },
}
