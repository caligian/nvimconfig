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
    if p == '/' then return p end
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

function B.exists(p, line)
  local is_valid
  is_valid, p, what = B.is_valid_path(p)
  if not is_valid then return false end
  local exists = B.bookmarks[p]
  if line then
    if not exists[line] then return false end
    return exists[line], "linenum"
  end
  return what
end

function B.update(p, line)
  local is_valid, p, what = B.is_valid_path(p)
  if not is_valid then return false end

  if what == "buffer" then
    if not is_a.t(B.bookmarks[p]) then B.bookmarks[p] = {} end
    local b = B.bookmarks[p]
    local bufnr = B.path2bufnr(p)
    local lc = vim.api.nvim_buf_line_count(bufnr)

    if is_a.n(line) then
      if line < 1 then return end
      if lc < line then return false end
      local context = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1]
      b[line] = context
    elseif line == "." then
      vim.api.nvim_buf_call(
        B.path2bufnr(p),
        function ()
          b[vim.fn.line('.')] = vim.fn.getline('.')
        end
      )
    else
      B.bookmarks[p] = {}
    end

    table.each(table.keys(b), function (linenum)
      if linenum > lc then
        b[linenum] = nil
      end
    end)
  elseif what == "file" then
    local s = vim.split(file.read(p), "\n")
    local lc = #s

    if line then
      if not is_a.t(B.bookmarks[p]) then B.bookmarks[p] = {} end
      if line > lc or lc < 1 then return false end
      B.bookmarks[p][line] = s[line]
    else
      if not is_a.t(B.bookmarks[p]) then
        B.bookmarks[p] = 'file'
      end
    end

    table.each(table.keys(B.bookmarks[p]), function (linenum)
      if linenum > lc then
        b[linenum] = nil
      end
    end)
  else
    B.bookmarks[p] = 'dir'
  end

  return B.bookmarks
end

function B.remove(p, line)
  local is_valid, waht
  is_valid, p, what = B.is_valid_path(p)
  if not is_valid then return false end
  local b = B.bookmarks[p]

  if what == 'file' then
    if line and b[line]  then
      local context = b[line]
      b[line] = nil
    else
      B.bookmarks[p] = nil
    end
  elseif what == 'dir' then
    B.bookmarks[p] = nil
  elseif line then
    b[line] = nil
  else
    B.bookmarks[p] = nil
  end

  return B.bookmarks
end

function Bookmarks.load()
  Bookmarks.bookmarks = loadfile(Bookmarks.dest)()
  return Bookmarks.bookmarks
end

function Bookmarks.save()
  file.write(Bookmarks.dest, "return " .. dump(Bookmarks.bookmarks))
end

function Bookmarks.add(p, line)
  B.update(p, line)
end

function Bookmarks.list(path, what)
  if not path then
    local b = table.keys(Bookmarks.bookmarks)
    if #b > 0 then return b end
    return table.keys(Bookmarks.bookmarks)
  end

  if what == 'dir' then
    return table.grep(table.values(B.bookmarks), function (x)
      if x == 'dir' then
        return true 
      end
      return false
    end)
  else
    return table.map(table.values(B.bookmarks), function (x)
      if is_a.t(x) then
        return table.items(x)
      end
      return {}
    end)
  end
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
