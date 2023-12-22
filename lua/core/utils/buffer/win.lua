Win = module()
Winid = dict.merge(module(), nvim.win)
Tabpage = dict.merge(module(), nvim.tabpage)

local function wrap(f)
  return function(winnr, ...)
    local exists = vim.fn.win_getid(winnr)

    if exists == 0 then
      return
    else
      return f(winnr, ...)
    end
  end
end

Winid.exists = Winid.is_valid

function Win.nr2id(winnr)
  local id = vim.fn.win_getid(winnr)
  if id == 0 then
    return
  end

  return id
end

Win.exists = wrap(identity)

function Winid.id2nr(winid)
  local ok = vim.fn.win_id2win(winid)

  if ok == 0 then
    return
  end

  return ok
end

Winid.winnr = Winid.id2nr

function Winid.bufnr(winid)
  local winnr = Winid.winnr(winid)

  if not winnr then
    return
  end

  local bufnr = vim.fn.winbufnr(winnr)
  return bufnr
end

function Winid.bufname(winid)
  local bufnr = Winid.bufnr(winid)
  return defined(bufnr and nvim.buf.get_name(bufnr))
end

Winid.winnr = Winid.id2nr

function Win.winnr(expr)
  if expr == nil then
    return vim.fn.winnr()
  end

  return vim.fn.winnr(expr)
end

Win.winid = Win.nr2id

function Win.current()
  return vim.fn.winnr()
end

function Winid.current()
  return Win.nr2id(Win.current())
end

function Win.currentid()
  return Win.id.current()
end

Win.height = wrap(function(winnr)
  return vim.fn.winheight(winnr)
end)

Win.width = wrap(function(winnr)
  return vim.fn.winwidth(winnr)
end)

Win.size = wrap(function(winnr)
  local width, height = Win.width(winnr), Win.height(winnr)

  if not width or not height then
    return
  end

  return { width, height }
end)

function Winid.set_vars(winid, vars)
  local out = {}

  for key, value in pairs(vars) do
    out[key] = nvim.win.set_var(winid, key, value)
  end

  return out
end

function Winid.get_options(winid, options)
  local out = {}

  for i = 1, #options do
    out[options[i]] = nvim.win.get_option(winid, options[i])
  end

  return out
end

function Winid.set_options(winid, options)
  local out = {}

  for key, value in pairs(options) do
    out[key] = nvim.win.set_option(winid, key, value)
  end

  return out
end

function Winid.get_vars(winid, vars)
  local out = {}

  for i = 1, #vars do
    out[vars[i]] = nvim.win.get_var(winid, var)
  end

  return out
end

function Winid.pos(winid, expr)
  winid = winid or Winid.current()

  return Winid.call(winid, function()
    local pos = vim.fn.getpos(expr or ".")
    return {
      bufnr = vim.fn.bufnr(),
      winid = winid,
      winnr = Winid.id2nr(winid),
      row = pos[2],
      col = pos[3],
      offset = pos[4],
    }
  end)
end

Win.getpos = Win.pos

function Winid.restcmd(winid)
  return Winid.call(winid, function()
    return vim.fn.winrestcmd()
  end)
end

function Winid.focus(id)
  return vim.fn.win_gotoid(id) ~= 0
end

function Winid.restview(winid, view)
  return Winid.call(winid, function()
    if isa.string(view) then
      vim.cmd(view)
    else
      vim.fn.winrestview(view)
    end

    return true
  end)
end

function Winid.saveview(winid)
  return Winid.call(winid, function()
    return vim.fn.winsaveview()
  end)
end

function Winid.currentline(winid)
  return Winid.call(winid, function()
    return vim.fn.getline "."
  end)
end

function Winid.linenum(winid)
  return Winid.call(winid, function()
    return vim.fn.line "."
  end)
end

function Tabpage.layouts(tab)
  local out

  if tab == nil then
    out = vim.fn.winlayout()
  else
    out = vim.fn.winlayout(tab)
  end

  if #out == 0 then
    return
  end

  return out
end

function Winid.virtualcol(winid)
  return Winid.call(winid, function()
    return vim.fn.wincol()
  end)
end

Win.bufname = wrap(function(winnr)
  return nvim.buf.get_name(vim.fn.winbufnr(winnr))
end)

Win.bufnr = wrap(function(winnr)
  return vim.fn.winbufnr(winnr)
end)

Win.move = wrap(function(from_winnr, towinnr, opts)
  if not Win.exists(towinnr) then
    return
  end

  vim.fn.win_splitmove(
    from_winnr,
    towinnr,
    opts or { right = true }
  )

  return true
end)

Win.screenpos = wrap(function(winnr)
  winnr = winnr or Win.current()

  if not Win.exists(winnr) then
    return
  end

  return vim.fn.win_screenpos(winnr)
end)

Win.move_statusline = wrap(function(winnr, offset)
  return vim.fn.win_move_statusline(winnr, offset) ~= 0
end)

Win.move_separator = wrap(function(winnr, offset)
  return vim.fn.win_move_separator(winnr, offset) ~= 0
end)

Winid.tabpage = wrap(function(winid)
  local out = vim.fn.win_id2tabwin(winid)
  if out[1] == 0 and out[2] == 0 then
    return
  end

  return out
end)

Win.type = wrap(function(winnr)
  return vim.fn.win_gettype(winnr)
end)

function Winid.col(winid, expr)
  return Winid.call(winid, function()
    expr = expr or "."
    return vim.fn.col(expr)
  end)
end

function Winid.row(winid, expr)
  return Winid.call(winid, function()
    expr = expr or "."
    return vim.fn.line(expr)
  end)
end

function Winid.curpos(winid)
  local row = Winid.row(winid)
  local col = Winid.col(winid)
  if not row or not col then
    return
  end

  return { row, col, row = row, col = col }
end

function Winid.range(winid)
  local out = {}

  Winid.call(winid or Winid.current(), function()
    if vim.fn.mode() == "v" then
      vim.cmd "normal! "
    end

    local _, csrow, cscol, _ = unpack(vim.fn.getpos "'<")
    local _, cerow, cecol, _ = unpack(vim.fn.getpos "'>")

    if csrow > cerow or cscol > cecol then
      return
    end

    out = {
      csrow,
      cscol,
      cerow,
      cecol,
      bufnr = Winid.bufnr(winid),
      row = { csrow, cerow },
      col = { cscol, cecol },
    }
  end)

  return out
end

local function range_text(buf, ...)
  local args = { ... }
  args = list.map(args, function(x)
    return x - 1
  end)
  args[#args + 1] = {}

  return vim.api.nvim_buf_get_text(buf, unpack(args))
end

function Winid.range_text(winid)
  winid = winid or Winid.current()
  local range = Winid.range(winid)
  if not range then
    return
  end

  local csrow, cerow = unpack(range.row)
  local cscol, cecol = unpack(range.col)
  local buf = Winid.bufnr(winid)

  return range_text(buf, csrow, cscol, cerow, cecol)
end

function Winid.is_visible(winid)
  return Winid.winnr(winid) and winid
end

Winid.getpos = Winid.pos

local exclude = {
  id2nr = true,
  bufnr = true,
  current = true,
  bufname = true,
}

dict.each(Winid, function(key, value)
  if not exclude[key] then
    Win[key] = function(winnr, ...)
      local winid = Win.nr2id(winnr)

      if winid then
        return value(winid, ...)
      end
    end
  end
end)
