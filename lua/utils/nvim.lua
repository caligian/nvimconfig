function buffer_has_keymap(bufnr, mode, lhs)
  bufnr = bufnr or 0
  local keymaps = vim.api.nvim_buf_get_keymap(bufnr, mode)
  lhs = lhs:gsub("<leader>", vim.g.mapleader)
  lhs = lhs:gsub("<localleader>", vim.g.maplocalleader)

  return index(keymaps, lhs, function(t, item)
    return t.lhs == item
  end)
end

function visualrange(bufnr)
  return vim.api.nvim_buf_call(bufnr or vim.fn.bufnr(), function()
    local _, csrow, cscol, _ = unpack(vim.fn.getpos "'<")
    local _, cerow, cecol, _ = unpack(vim.fn.getpos "'>")
    if csrow < cerow or (csrow == cerow and cscol <= cecol) then
      return vim.api.nvim_buf_get_text(0, csrow - 1, cscol - 1, cerow - 1, cecol, {})
    else
      return vim.api.nvim_buf_get_text(0, csrow - 1, cscol - 1, cerow - 1, cscol, {})
    end
  end)
end

function nvimerr(...)
  for _, s in ipairs { ... } do
    vim.api.nvim_err_writeln(s)
  end
end

function nvimexec(s, output)
  output = output == nil and true or output
  return vim.api.nvim_exec(s, output)
end

-- If multiple keys are supplied, the table is going to be assumed to be nested
function req(require_string, do_assert)
  local ok, out = pcall(require, require_string)
  if ok then
    return out
  end

  local no_file = false
  no_file = out:match "^module '[^']+' not found"

  if no_file then
    out = "Could not require " .. require_string
  end

  makepath(user, "logs")
  append(user.logs, out)
  logger:debug(out)

  if do_assert then
    error(out)
  end
end

function glob(d, expr, nosuf, alllinks)
  nosuf = nosuf == nil and true or false
  return vim.fn.globpath(d, expr, nosuf, true, alllinks) or {}
end

function get_font()
  font = vim.o.guifont:match "^([^:]+)"
  height = vim.o.guifont:match "h([0-9]+)" or 12
  return font, height
end

function set_font(font, height)
  validate {
    ["?font"] = { "s", font },
    ["?height"] = { "n", height },
  }

  local current_font, current_height = get_font()
  if not font then
    font = current_font
  end
  if not height then
    height = current_height
  end

  font = font:gsub(" ", "\\ ")
  vim.cmd("set guifont=" .. sprintf("%s:h%d", font, height))
end

function log_pcall(f, ...)
  local ok, out = pcall(f, ...)
  if ok then
    return out
  else
    logger:debug(out)
  end
end
