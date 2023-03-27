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

  if not buftype:match_any("prompt", "nofile") then
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
  if not ok and file.exists(bufnr_or_path) then
    return path.abspath(bufnr_or_path), "path"
  elseif ok then
    return ok.bufname
  end
  return ok, msg
end

local function remove_path(buf_or_path, line)
  local path = get_buffer_or_path(buf_or_path)
  local exists = Marks.marks[path]
  if exists then
    if line then
      exists[line] = nil
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
  return vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1]
end

local function update_path(path, line)
  local buf, p = get_buffer_or_path(path)
  if not buf then return end
  local context

  if p == "path" then
    context = get_line_from_file(path, line)
  else
    local bufnr = vim.fn.bufnr(path)
    context = get_context(bufnr, line)
  end

  return table.update(Marks.marks, { path, line }, context)
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

function Marks.save() utils.dump_to_file(Marks.dest, Marks.marks) end

function Marks.add(bufnr, line)
  bufnr = bufnr or vim.fn.bufnr()
  line = line or vim.api.nvim_buf_call(bufnr, partial(vim.fn.line, "."))
  return update_mark(bufnr, line)
end

function Marks.remove(bufnr, line)
  if vim.fn.bufexists(bufnr) == 0 then return false end
  local bufname = vim.fn.bufname(bufnr)

  if not line then
    Marks.marks[bufname] = nil
  else
    local marked = Marks.marks[bufname][line]
    Marks.marks[bufname][line] = nil
    return marked
  end
end

Marks.cleanup = update_all_marks
