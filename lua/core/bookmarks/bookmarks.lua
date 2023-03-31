if not Bookmarks then Bookmarks = {} end
local B = Bookmarks
Bookmarks.dest = vim.fn.stdpath "data" .. "/bookmarks.lua"
Bookmarks.bookmarks = Bookmarks.bookmarks or {}
local _cached = {}

if not path.exists(Bookmarks.dest) then
  file.write(Bookmarks.dest, "return {}")
end

local function clean_cache()
  table.each(table.keys(_cached), function(x)
    local v = _cached[x]
    if not path.exists(v.path) then _cached[x] = nil end
  end)
end

function B.get_path(p)
  validate.path(is { "s", "n" }, p)

  local cached = _cached[p]
  if cached then
    if path.exists(cached.path) then
      return cached
    else
      _cached[p] = nil
      return
    end
  end

  local fullpath
  local bufnr
  local get_name = vim.api.nvim_buf_get_name

  if is_a.n(p) then
    if vim.fn.bufexists(p) ~= 1 then
      return false, "saved buffer expected, got " .. p
    end
    local buftype = vim.api.nvim_buf_get_option(p, "buftype")
    fullpath = get_name(p)
    local loaded = vim.fn.bufloaded(fullpath) == 1
    if buftype == "nofile" and not path.exists(fullpath) then
      error("buftype=nofile is set for " .. fullpath)
    elseif not loaded then
      error(fullpath .. " is not loaded. You need to save it")
    end

    local isdir = path.isdir(fullpath)

    local save = {
      path = fullpath,
      bufnr = p,
      dir = isdir,
      buffer = true,
      file = not isdir,
    }
    _cached[p] = save
    _cached[fullpath] = save

    return save
  end

  bufnr = vim.fn.bufnr(p)
  if bufnr == -1 then
    _cached[p] = nil
    fullpath = path.abspath(p)
    if path.exists(fullpath) then
      local save
      if path.isdir(fullpath) then
        save = { path = fullpath, dir = true }
      else
        save = { path = fullpath, file = true }
      end
      _cached[p] = save
      _cached[fullpath] = save

      return save
    else
      _cached[p] = nil
    end
  else
    fullpath = get_name(bufnr)
    local save = {
      path = fullpath,
      buffer = true,
      bufnr = bufnr,
      dir = path.isdir(fullpath),
    }
    _cached[bufnr] = save
    _cached[p] = save
    _cached[fullpath] = save

    return save
  end
end

function B.is_valid_path(p) return B.get_path(p) or false end

function B.exists(p)
  p = B.get_path(p)
  if not p then return false end
  return B.bookmarks[p.path] or false
end

function B.path2bufnr(p)
  p = B.get_path(p)
  if not p or not p.buffer then return false end
  return p.bufnr
end

function B.get_path_len(p)
  p = B.get_path(p)
  if not p or p.dir then return false end
  if p.buffer then return vim.api.nvim_buf_line_count(p.bufnr) end

  return #vim.split(file.read(p.path), "\n")
end

function B.clean(p)
  table.each(B.bookmarks, function(check)
    if not B.is_valid_path(check) then B.bookmarks[p] = nil end
  end)

  if #table.keys(B.bookmarks) == 0 then return end
  if not p then return end
  p = B.get_path(p)

  if not B.bookmarks[p] then return end

  local exists = B.exists(p.path)
  if not is_a.t(exists) then return end
  local lc = B.get_path_len(p.path)

  table.teach(exists, function(line, context)
    if lc < line then B.bookmarks[p.path][line] = nil end
    B.bookmarks[p.path][line] = B.get_context(p.path, line)
  end)

  clean_cache()
end

function B.get_context(p, line)
  p = B.get_path(p)

  if not p or p.dir or p.type == "dir" then return false end

  if p.type == "file" then
    local s = vim.split(file.read(p.path), "\n")
    return s[line]
  end

  return vim.api.nvim_buf_get_lines(p.bufnr, line - 1, line, false)
end

function B.update(p, line)
  validate["?line"](function(x) return x == "." or is_a.n(x) end, line)

  p = B.get_path(p)

  if not p then return end

  if p.buffer then
    if p.dir then
      B.bookmarks[p.path] = "dir"
    else
      local b = B.exists(p.path)
      if not b then 
        B.bookmarks[p.path] = {} 
        b = B.bookmarks[p.path]
      end
      local bufnr = p.bufnr
      if is_a.n(line) then
        b[line] = B.get_context(p, line)
      elseif line == "." then
        vim.api.nvim_buf_call(p.bufnr, function()
          local pos = vim.fn.line "."
          b[vim.fn.line "."] = vim.fn.getline "."
        end)
      end
    end
  elseif not p.dir then
    assert(line ~= ".", "line number expected, got cursor position spec")

    if line then
      local s = B.get_context(p.path, line)
      if s then b[line] = s end
    else
      B.bookmarks[p.path] = B.bookmarks[p.path] or {}
    end
  else
    B.bookmarks[p.path] = "dir"
  end

  B.clean(p.path)

  return B.bookmarks
end

function B.remove(p, line)
  p = B.get_path(p)
  if not p then return end
  local b = B.exists(p.path)
  if not b then return end

  if p.dir then
    B.bookmarks[p.path] = nil
  else
    if is_a.t(b) then
      if line then
        b[line] = nil
      else
        B.bookmarks[p.path] = nil
      end
    else
      B.bookmarks[p.path] = nil
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
  B.update(p, line)
end

function B.list(p)
  B.clean()

  if not p then
    local b = table.keys(Bookmarks.bookmarks)
    if #b > 0 then return b end
    return
  end

  local b = B.exists(p)
  if is_a.t(b) then return b end
end

function B.jump(p, line, split)
  B.clean()

  p = B.get_path(p)
  if not p then return end

  if not p.buffer then
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
