if not Bookmarks then Bookmarks = {} end
local B = Bookmarks
Bookmarks.dest = vim.fn.stdpath "data" .. "/bookmarks.lua"
Bookmarks.bookmarks = Bookmarks.bookmarks or {}

if not path.exists(Bookmarks.dest) then
  file.write(Bookmarks.dest, "return {}")
end

function B.is_valid_path(p)
  if is_a.n(p) then
    p = vim.fn.bufnr(p)
    if p == -1 then return false, p .. " is an invalid buffer" end
    local buftype = vim.api.nvim_buf_get_option(p, "buftype")
    p = vim.api.nvim_buf_get_name(p)
    if buftype == "nofile" then
      return false, p .. "has buftype=nofile", "buffer"
    elseif not path.exists(p) then
      return false, p .. " is nonexistent. Save the buffer", "file"
    end
    return true, p, "buffer"
  elseif is_a.s(p) then
    if vim.fn.bufexists(p) == 1 then return B.is_valid_path(vim.fn.bufnr(p)) end
    if p == "/" then return p end
    p = path.abspath(p)
    if not path.exists(p) then return false end
    if path.isdir(p) then return true, p, "dir" end
    return true, p, "file"
  end
  return false
end

function B.path2bufnr(bufpath)
  local is_valid, p, what = B.is_valid_path(bufpath)
  if not is_valid then return false end
  if what == "buffer" then return vim.fn.bufnr(p) end
  return false
end

function B.get_path_len(p)
  local is_valid, what
  is_valid, p, what = B.is_valid_path(p)
  if not is_valid or what == "dir" then return end
  if what == "buffer" then
    return vim.api.nvim_buf_line_count(vim.fn.bufnr(p))
  end

  return #vim.split(file.read(p), "\n")
end

function B.exists(p, line)
  local is_valid
  is_valid, p, what = B.is_valid_path(p)
  if not is_valid then return false end
  local exists = B.bookmarks[p]
  return exists[line] or exists[line] or exists or what
end

function B.clean(p)
  table.each(B.bookmarks, function(check)
    if not B.is_valid_path(check) then B.bookmarks[p] = nil end
  end)

  if #table.keys(B.bookmarks) == 0 then return end
  local is_valid
  local exists = B.bookmarks[p]
  if not is_a.t(exists) then return end
  local lc = B.get_path_len(p)

  table.teach(exists, function(line, context)
    if lc < line then B.bookmarks[p][line] = nil end
    B.bookmarks[p][line] = B.get_context(p, line)
  end)
end

function B.update(p, line)
  validate.path("s", p)
  validate["?line"](function (x)
    return x == '.' or is_a.n(x)
  end, line)

  local is_valid, what
  is_valid, p, what = B.is_valid_path(p)
  if not is_valid then return false end

  if what == "buffer" then
    if not is_a.t(B.bookmarks[p]) then B.bookmarks[p] = {} end
    local b = B.bookmarks[p]
    local bufnr = B.path2bufnr(p)
    local lc = vim.api.nvim_buf_line_count(bufnr)

    if is_a.n(line) then
      b[line] = B.get_context(p, line)
    elseif line == "." then
      vim.api.nvim_buf_call(B.path2bufnr(p), function()
        local pos = vim.fn.line "."
        b[vim.fn.line "."] = vim.fn.getline "."
      end)
    end
  elseif what == "file" then
    local s = vim.split(file.read(p), "\n")
    local lc = #s
    assert(line ~= ".", "line number expected, got cursor position spec")

    if line then
      b[line] = B.get_context(p, line)
    else
      B.bookmarks[p] = B.bookmarks[p] or {}
    end
  else
    B.bookmarks[p] = "dir"
  end

  B.clean(p)

  return B.bookmarks
end

function B.remove(p, line)
  is_valid, p = B.is_valid_path(p)
  if not is_valid then return end
  local b = B.bookmarks[p]
  if not b then return end

  if b == "dir" then
    B.bookmarks[p] = nil
  else
    if is_a.t(b) then
      if line then
        b[line] = nil
      else
        B.bookmarks[p] = nil
      end
    else
      B.bookmarks[p] = nil
    end
  end

  B.clean()
end

function B.load()
  Bookmarks.bookmarks = loadfile(Bookmarks.dest)()
  B.clean()
  return Bookmarks.bookmarks
end

function B.save()
  B.clean()
  file.write(Bookmarks.dest, "return " .. dump(Bookmarks.bookmarks))
end

function B.add(p, line)
  p = p or vim.fn.bufnr()
  local is_valid, p = B.is_valid_path(p)
  if not is_valid then error(p) end
  B.update(p, line)
end

function B.get_context(p, line)
  local is_valid, what
  is_valid, p, what = B.is_valid_path(p)
  if not what:match_any("file", "buffer") then return end

  if what == "file" then
    local s = vim.split(file.read(p), "\n")
    return s[line]
  end
  return vim.api.nvim_buf_get_lines(vim.fn.bufnr(p), line - 1, line, false)
end

function B.list(p, what)
  B.clean()

  if not p then
    local b = table.keys(Bookmarks.bookmarks)
    if #b > 0 then return b end
    return false
  end

  if what == "dir" then
    local d = table.grep(table.values(B.bookmarks), function(x)
      if x == "dir" then return true end
      return false
    end)
    if #d > 0 then return d end
    return false
  else
    local is_valid
    is_valid, p = B.is_valid_path(p)
    if not is_valid then return false end
    if not B.bookmarks[p] then return false end
    return B.bookmarks[p]
  end
end

function B.jump(p, line, split)
  B.clean()

  local is_valid, what
  is_valid, p, what = B.is_valid_path(p)
  if not is_valid then error(p) end

  if what == "file" then
    if split == "s" then
      vim.cmd(":split " .. p)
    elseif split == "v" then
      vim.cmd(":vsplit " .. p)
    elseif split == "t" then
      vim.cmd(":tabnew " .. p)
    else
      vim.cmd(":e " .. p)
    end
  else
    if split == "s" then
      vim.cmd(":split | b " .. p)
    elseif split == "v" then
      vim.cmd(":vsplit | b " .. p)
    elseif split == "t" then
      vim.cmd(":tabnew | b " .. p)
    else
      vim.cmd(":b " .. p)
    end
  end
  if line then vim.cmd("normal! " .. line .. "G") end
end

function B.delete_all()
  if not path.exists(Bookmarks.dest) then return end
  vim.fn.system { "rm", Bookmarks.dest }
end
