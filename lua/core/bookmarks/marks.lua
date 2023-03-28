require "core.bookmarks.bookmarks"
local utils = require "core.bookmarks.utils"

if not Marks then Marks = {} end
Marks.dest = vim.fn.stdpath "data" .. "/bookmarks.lua"
Marks.marks = Marks.marks or {}

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

local function assert_valid_buffer(buf)
  local ok, msg = is_valid_buffer(buf)
  if not ok then error(msg) end
  return ok
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
    return vim.api.nvim_buf_call(get_bufnr(bufnr_or_path), function ()
      return vim.fn.expand("%:p")
    end)
  end
  return ok, msg
end

local function remove_path(buf_or_path, ...)
  local path = get_buffer_or_path(buf_or_path)
  local exists = Marks.marks[path]
  local lines = {...}
  if exists then
    if #lines > 0 then
      table.each(lines, function (x)
        exists[x] = nil
      end)
    else
      Marks.marks[path] = nil
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
  if not buf then 
    if Marks.marks[buf] then
      Marks.marks[buf] = nil
    end
    return 
  end

  if p == "path" then
    local context = get_line_from_file(buf, line)
    return table.update(Marks.marks, { buf, line }, context)
  else
    local bufnr = vim.fn.bufnr(buf)
    local context = get_context(bufnr, line)
    if context then
      return table.update(Marks.marks, { buf, line }, context)
    else
      remove_path(buf, line)
    end
  end
end

local function update_all_marks()
  table.teach(
    Marks.marks,
    function(path, lines)
      table.each(table.keys(lines), partial(update_path, path))
    end
  )
end

function Marks.load()
  Marks.marks = utils.load_file(Marks.dest)
  return Marks.marks
end

function Marks.save() 
  utils.dump_to_file(Marks.dest, Marks.marks) 
end

function Marks.add(bufnr, line)
  bufnr = bufnr or vim.fn.bufnr()
  line = line or vim.api.nvim_buf_call(bufnr, function ()
    return vim.fn.line('.')
  end)
  return update_path(bufnr, line)
end

function Marks.list(path)
  local bufname = get_buffer_or_path(path or vim.fn.bufnr())
  if Marks.marks[bufname] then
    return table.items(Marks.marks[bufname])
  end
  return false
end
