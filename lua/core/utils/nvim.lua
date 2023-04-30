function utils.nvimerr(...)
  for _, s in ipairs { ... } do
    vim.api.nvim_err_writeln(s)
  end
end

function utils.nvimexec(s, output)
  output = output == nil and true or output
  return vim.api.nvim_exec(s, output)
end

-- If multiple dict.keys are supplied, the table is going to be assumed to be nested
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

  dict.makepath(user, "logs")
  array.append(user.logs, out)
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
  local font, height
  font = user and user.font.family
  height = user and user.font.height
  font = vim.o.guifont:match "^([^:]+)" or font
  height = vim.o.guifont:match "h([0-9]+)" or height

  return font, height
end

function utils.set_font(font, height)
  local current_font, current_height = utils.get_font()
  font = font or current_font
  height = height or current_height
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
  for _, form in ipairs { ... } do
    assert(is_a.table(form) and #form >= 1, "form: {var, [rest vim.fn.input args]}")
    local name = form[1]
    local s = vim.fn.input(form[2] or name .. " % ", unpack(array.rest(array.rest(form))))

    if #s == 0 then
      pp("\nexpected string for param " .. name)
      return
    end
    out[name] = s
  end

  return out
end