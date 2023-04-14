function utils.buffer_has_keymap(bufnr, mode, lhs)
  bufnr = bufnr or 0
  local keymaps = vim.api.nvim_buf_get_keymap(bufnr, mode)
  lhs = lhs:gsub("<leader>", vim.g.mapleader)
  lhs = lhs:gsub("<localleader>", vim.g.maplocalleader)

  return table.index(keymaps, lhs, function(t, item)
    return t.lhs == item
  end)
end

function utils.visualrange(bufnr)
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

function utils.nvimerr(...)
  for _, s in ipairs { ... } do
    vim.api.nvim_err_writeln(s)
  end
end

function utils.nvimexec(s, output)
  output = output == nil and true or output
  return vim.api.nvim_exec(s, output)
end

-- If multiple table.keys are supplied, the table is going to be assumed to be nested
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

  table.makepath(user, "logs")
  table.append(user.logs, out)
  logger:debug(out)

  if do_assert then
    error(out)
  end
end

function utils.glob(d, expr, nosuf, alllinks)
  nosuf = nosuf == nil and true or false
  return vim.fn.globpath(d, expr, nosuf, true, alllinks) or {}
end

function utils.get_font()
  font = vim.o.guifont:match "^([^:]+)"
  height = vim.o.guifont:match "h([0-9]+)" or 12
  return font, height
end

function utils.set_font(font, height)
  pp(font, height)
  validate {
    ["?font"] = { "s", font },
    ["?height"] = { "n", height },
  }

  local current_font, current_height = utils.get_font()
  if not font then
    font = current_font
  end
  if not height then
    height = current_height
  end

  font = font:gsub(" ", "\\ ")
  vim.cmd("set guifont=" .. sprintf("%s:h%d", font, height))
end

function utils.log_pcall(f, ...)
  local ok, out = pcall(f, ...)
  if ok then
    return out
  else
    logger:debug(out)
  end
end

function utils.log_pcall_wrap(f)
  return function(...)
    return utils.log_pcall(f, ...)
  end
end

function throw_error(desc)
  error(dump(desc))
end

function utils.try_require(s, success, failure)
  local M = require(s)
  if M and success then
    return success(M)
  elseif not M and failure then
    return failure(M)
  end
  return M
end

function copy(obj, deep)
  if type(obj) ~= "table" then
    return obj
  elseif deep then
    return vim.deepcopy(obj)
  end

  local out = {}
  for key, value in pairs(obj) do
    out[key] = value
  end

  return out
end

function utils.command(name, callback, opts)
  opts = opts or {}
  return vim.api.nvim_create_user_command(name, callback, opts or {})
end

utils.del_command = vim.api.nvim_del_user_command

-- form: {var, <input-option> ...}
function input(...)
  local out = {}
  for _, form in ipairs {...} do
    assert(is_a.table(form) and #form >= 1, 'form: {var, [rest vim.fn.input args]}')
    local name = form[1]
    local s = vim.fn.input(form[2] or name .. ' % ', unpack(table.rest(table.rest(form))))
    
    if #s == 0 then pp("\nexpected string for param " .. name); return end
    out[name] = s
  end

  return out
end
