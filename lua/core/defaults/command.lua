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
  if V.is_type(lines, "table") then
    lines = table.concat(lines, "\n")
  end

  local compiled, err = loadstring(lines)
  if err then
    V.nvim_err(err)
  elseif compiled then
    compiled()
  end
end

-- Setup commands
V.command("NvimEvalRegion", function()
  local lines = V.get_visual_range()
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
