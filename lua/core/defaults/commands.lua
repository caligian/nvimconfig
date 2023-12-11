local command = vim.api.nvim_create_user_command

-- Open logs
command("ShowLogs", function()
  local log_path = vim.fn.stdpath "config" .. "/nvim.log"
  if path.exists(log_path) then
    vim.cmd("tabnew " .. log_path)
    vim.cmd "setlocal readonly"
    vim.cmd "noremap <buffer> q :bwipeout <bar> b#<CR>"
  end
end, {})

-- Open scratch buffer
command("OpenScratch", function()
  buffer.split(buffer.scratch "scratch", "s")
end, {})

command("OpenScratchVertically", function()
  buffer.split(buffer.scratch "scratch", "v")
end, {})

local function compile_and_run(lines)
  if isa(lines, "table") then
    lines = table.concat(lines, "\n")
  end

  local compiled, err = loadstring(lines)
  if err then
    tostderr(err)
  elseif compiled then
    compiled()
  end
end

-- Setup commands
command("NvimEvalRegion", function(opts)
  local lines = buffer.range_text(opts.buf)
  compile_and_run(lines)
end, {})

command("NvimEvalBuffer", function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  compile_and_run(lines)
end, {})

command("NvimEvalTillCursor", function()
  local line = vim.fn.line "."
  local lines = vim.api.nvim_buf_get_lines(0, 0, line - 1, false)
  compile_and_run(lines)
end, {})

command("NvimEvalLine", function()
  local line = vim.fn.getline "."
  compile_and_run(line)
end, {})

-- Only works for guifg and guibg
command("Darken", function(args)
  args = vim.split(args.args, " +")
  assert(#args == 2)

  local what, by = unpack(args)
  local hi = highlight "Normal"

  if isempty(hi) then
    return
  end

  local set = {}
  if what == "fg" then
    set["guifg"] = darken(hi["guifg"], tonumber(by))
  else
    set["guibg"] = darken(hi["guibg"], tonumber(by))
  end

  highlightset("Normal", set)
end, { nargs = "+" })

command("TrimWhiteSpace", function()
  local layout = vim.fn.winsaveview()
  vim.cmd "keeppatterns %s/\\s\\+$//e"
  vim.fn.winrestview(layout)
end, {})

command("EnableZenMode", function()
  vim.o.laststatus = 0
end, {})

command("ToggleZenMode", function()
  user.zenmode_toggled = vim.o.laststatus == 0
  if user.zenmode_toggled then
    user.zenmode_toggled = false
    vim.o.laststatus = 3
  else
    user.zenmode_toggled = true
    vim.o.laststatus = 0
  end
end, {})
