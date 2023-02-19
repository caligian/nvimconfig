-- Open logs
V.command("ShowLogs", function()
  local log_path = vim.fn.stdpath("config") .. "/nvim.log"
  if path.exists(log_path) then
    vim.cmd("e " .. log_path)
    vim.cmd("set readonly")
  end
end, {})

-- Open scratch buffer
V.command("OpenScratch", function()
  Buffer.open_scratch()
end, {})

V.command("OpenScratchVertically", function()
  Buffer.open_scratch(false, "v")
end, {})

-- Compile neovim lua
local function compile_and_run(lines)
  if V.isa(lines, "table") then
    lines = table.concat(lines, "\n")
  end

  local compiled, err = loadstring(lines)
  if err then
    V.err(err)
  elseif compiled then
    compiled()
  end
end

-- Setup commands
V.command("NvimEvalRegion", function()
  local lines = V.visualrange()
  compile_and_run(lines)
end, { range = true })

V.command("NvimEvalBuffer", function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  compile_and_run(lines)
end, {})

V.command("NvimEvalTillPoint", function()
  local line = vim.fn.line(".")
  local lines = vim.api.nvim_buf_get_lines(0, 0, line - 1, false)
  compile_and_run(lines)
end, {})

V.command("NvimEvalLine", function()
  local line = vim.fn.getline(".")
  compile_and_run(line)
end, {})

-- Only works for guifg and guibg
V.command("Darken", function(args)
  args = vim.split(args.args, " +")
  assert(#args == 2)

  local what, by = unpack(args)
  local hi = V.highlight("Normal")

  if V.isblank(hi) then
    return
  end

  local set = {}
  if what == "fg" then
    set["guifg"] = V.darken(hi["guifg"], tonumber(by))
  else
    set["guibg"] = V.darken(hi["guibg"], tonumber(by))
  end

  V.highlightset("Normal", set)
end, { nargs = "+" })

-- Only works with guifont
-- :FontSize points
V.command("FontSize", function(args)
  args = vim.split(args.args, " +")
  args = args[1]
  local font, height = string.match(vim.o.guifont, "([^:]+):h([0-9]+)")

  local inc = args:match("^([-+])")
  args = args:gsub("^[-+]", "")
  args = tonumber(args)
  if inc == "+" then
    height = height + args
  elseif inc == "-" then
    height = height - args
  else
    height = args
  end

  vim.cmd("set guifont=" .. sprintf("%s:h%d", font, height))
end, { nargs = "+" })
