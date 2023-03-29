if not Bookmarks then Bookmarks = {} end
Bookmarks.dest = vim.fn.stdpath "data" .. "/bookmarks.lua"
Bookmarks.bookmarks = Bookmarks.bookmarks or {}

if not path.exists(Bookmarks.dest) then
  file.write(Bookmarks.dest, "return {}")
end

local function is_valid_buffer(bufnr)
  if vim.fn.bufexists(bufnr) == 0 then return false end
  if is_a.s(bufnr) then bufnr = vim.fn.bufnr(bufnr) end

  local bufname = vim.fn.bufname(bufnr)
  local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")

  if buftype:match_any("prompt", "nofile") then
    return false,
      sprintf("buftype=%s not allowed while bookmarking %s", buftype, bufname)
  end

  return { bufnr = bufnr, bufname = bufname }
end

local function get_bufnr(buf)
  local ok, msg = is_valid_buffer(buf)
  if ok then return ok.bufnr end
  return false, msg
end

local function get_buffer_or_path(bufnr_or_path)
  local ok, msg = is_valid_buffer(bufnr_or_path)
  if not ok and path.exists(bufnr_or_path) then
    return path.abspath(bufnr_or_path), "path"
  elseif ok then
    return vim.api.nvim_buf_call(
      get_bufnr(bufnr_or_path),
      function() return vim.fn.expand "%:p" end
    )
  end
  return ok, msg
end

local function remove_path(buf_or_path, ...)
  local path = get_buffer_or_path(buf_or_path)
  local exists = Bookmarks.bookmarks[path]
  local lines = { ... }
  if exists then
    if #lines > 0 then
      table.each(lines, function(x) exists[x] = nil end)
    else
      Bookmarks.bookmarks[path] = nil
    end
  end
end

local function get_line_from_file(path, line)
  return vim.fn.system {
    "sed",
    line .. "q",
    path,
  }
end

local function get_context(bufnr, line)
  local lc = vim.api.nvim_buf_line_count(bufnr)
  if line > lc then return false end
  line = line - 1
  return vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1]
end

local function update_path(path, line)
  local buf, p = get_buffer_or_path(path)

  if p == "path" then
    local context = get_line_from_file(buf, line)
    return table.update(Bookmarks.bookmarks, { buf, line }, context)
  else
    local bufnr = vim.fn.bufnr(buf)
    local context = get_context(bufnr, line)
    if context then
      table.update(Bookmarks.bookmarks, { buf, line }, context)
    else
      remove_path(buf, line)
    end
  end
end

function Bookmarks.update()
  table.teach(
    Bookmarks.bookmarks,
    function(path, lines)
      table.each(table.keys(lines), partial(update_path, path))
    end
  )
end

function Bookmarks.load()
  Bookmarks.bookmarks = loadfile(Bookmarks.dest)()
  return Bookmarks.bookmarks
end

function Bookmarks.save()
  file.write(Bookmarks.dest, "return " .. dump(Bookmarks.bookmarks))
end

function Bookmarks.add(bufnr, line)
  local path, is_path = get_buffer_or_path(bufnr or vim.fn.bufnr())
  if not is_path then
    bufnr = vim.fn.bufnr(path)
    line = line
      or vim.api.nvim_buf_call(bufnr, function() return vim.fn.line "." end)
  else
    line = get_line_from_file(path, line)
  end

  return update_path(path, line)
end

function Bookmarks.list(path)
  if not path then 
    local b = table.keys(Bookmarks.bookmarks) 
    if #b > 0 then
      return b
    end
    return table.keys(Bookmarks.bookmarks) 
  end

  local bufname = get_buffer_or_path(path or vim.fn.bufnr())
  local exists = Bookmarks.bookmarks[bufname]
  if exists and #table.keys(exists) > 0 then
    return table.items(exists)
  end
  return false
end

function Bookmarks.remove(path, ...)
  path = path or vim.api.nvim_buf_get_name(vim.fn.bufnr())
  remove_path(path, ...)
end

function Bookmarks.jump(path, line)
  local is_path
  path, is_path = get_buffer_or_path(path)

  if is_path then
    vim.cmd(":e " .. path)
  else
    vim.cmd(":b " .. path)
  end

  if line then vim.cmd("normal! " .. line .. "G") end
end

function Bookmarks.delete()
  if not path.exists(Bookmarks.dest) then return end
  vim.fn.system { "rm", Bookmarks.dest }
end
