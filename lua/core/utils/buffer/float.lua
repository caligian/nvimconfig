require 'core.utils.buffer.win'

local float = {}

--------------------------------------------------
local function from_percent(current, width, min)
  current = current or vim.fn.winwidth(0)
  width = width or 0.5

  assert(width ~= 0, "width cannot be 0")
  assert(width > 0, "width cannot be < 0")

  if width < 1 then
    required = math.floor(current * width)
  else
    return width
  end

  if min < 1 then
    min = math.floor(current * min)
  else
    min = math.floor(min)
  end

  if required < min then
    required = min
  end

  return required
end

function float.float_opts(opts)
  return {
    relative = opts.relative,
    style = opts.style,
    border = opts.border,
    win = opts.win,
    anchor = opts.anchor,
    width = opts.width,
    height = opts.height,
    bufpos = opts.bufpos,
    row = opts.row,
    col = opts.col,
    focusable = opts.focusable,
    external = opts.external,
    zindex = opts.zindex,
    title = opts.title,
    title_pos = opts.title_pos,
    noautocmd = opts.noautocmd,
  }
end

local function vimsize()
  local scratch = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_call(scratch, function()
    vim.cmd "tabnew"
    local tabpage = vim.fn.tabpagenr()
    width = vim.fn.winwidth(0)
    height = vim.fn.winheight(0)
    vim.cmd("tabclose " .. tabpage)
  end)

  vim.cmd(":bwipeout! " .. scratch)

  return { width, height }
end

function float.float(bufnr, opts)
  opts = opts or {}
  bufnr = bufnr or buffer.current()
  opts = opts or {}
  local dock = opts.dock
  local panel = opts.panel
  local center = opts.center
  local focus = opts.focus
  opts.style = opts.style or "minimal"
  opts.border = opts.border or "single"
  local editor_size = vimsize()
  local current_width = Win.width()
  local current_height = Win.height()
  opts.width = opts.width or current_width
  opts.height = opts.height or current_height
  opts.relative = opts.relative or "editor"
  focus = focus == nil and true or focus
  local reverse = opts.reverse
  local temp = opts.temp

  if center then
    if opts.relative == "editor" then
      current_width = editor_size[1]
      current_height = editor_size[2]
    end

    center = center == true and {0.8, 0.8} or center
    local width, height = unpack(center)
    width = math.floor(from_percent(current_width, width, 10))
    height = math.floor(from_percent(current_height, height, 5))
    local col = (current_width - width) / 2
    local row = (current_height - height) / 2
    opts.width = width
    opts.height = height
    opts.col = math.floor(col)
    opts.row = math.floor(row)
  elseif panel then
    if opts.relative == "editor" then
      current_width = editor_size[1]
      current_height = editor_size[2]
    end

    panel = panel == true and 0.3 or panel
    opts.row = 0
    opts.col = 1
    opts.width = from_percent(current_width, panel, 5)
    opts.height = current_height

    if reverse then
      opts.col = current_width - opts.width
    end
  elseif dock then
    dock = dock == true and 0.3 or dock

    if opts.relative == "editor" then
      current_width = editor_size[1]
      current_height = editor_size[2]
    end

    opts.col = 0
    opts.row = opts.height - dock
    opts.height = from_percent(current_height, dock, 5)
    opts.width = current_width > 5 and current_width - 2 or current_width

    if reverse then
      opts.row = opts.height
    end

    opts.row = math.floor(opts.row)
  end

  local winid = vim.api.nvim_open_win(bufnr, focus, float.float_opts(opts))

  if winid == 0 then
    return false
  end

  return winid
end

function float.panel(bufnr, size, opts)
  if not size then
    size = 0.3
  end

  local o = dict.merge({ panel = size }, { opts or {} })
  return float.float(bufnr, o)
end

function float.center_float(bufnr, size, opts)
  if not size then
    size = { 0.8, 0.8 }
  elseif is_number(size) then
    local n = size
    size = { n, n }
  elseif #size == 1 then
    local n = size[1]
    size = { n, n }
  end

  return float.float(bufnr, dict.merge({ center = size }, { opts }))
end

function float.dock(bufnr, size, opts)
  size = size or 10

  return float.float(bufnr, dict.merge({ dock = size }, { opts or {} }))
end

function float.set_float_config(bufnr, config)
  config = config or {}
  local winnr = vim.fn.bufwinnr(bufnr)

  local ok, msg = pcall(vim.api.nvim_win_set_config, vim.fn.win_getid(winnr), config)

  if not ok then
    return
  end

  return true
end

function float.get_float_config(bufnr)
  local winnr = nvim.fn.bufwinnr(bufnr)
  if winnr == -1 then
    return
  end

  local ok, msg = pcall(vim.api.nvim_win_get_config, vim.fn.win_getid(winnr))

  if not ok then
    return false, msg
  end

  return ok
end

return float
