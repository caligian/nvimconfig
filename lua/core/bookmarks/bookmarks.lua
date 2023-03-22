if not Bookmarks then
  Bookmarks = {
    dest = path.join(vim.fn.stdpath "config", "bookmarks.lua"),
  }
end

Bookmarks.bookmarks = Bookmarks.bookmarks or {}

if not path.exists(Bookmarks.dest) then
  fh = io.open(Bookmarks.dest, "w")
  if fh then
    fh:write "return {}"
    fh:close()
  end
end

function Bookmarks.load()
  Bookmarks.bookmarks = loadfile(Bookmarks.dest)()
  return Bookmarks.bookmarks
end

function Bookmarks.save()
  local s = "return " .. dump(Bookmarks.bookmarks)
  file.write(Bookmarks.dest, s)
end

function Bookmarks.add(fname)
  if fname then
    fname = path.abspath(fname)
  else
    local bufnr = vim.fn.bufnr()
    local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
    if buftype:match_any("terminal", "prompt") then return end
    fname = vim.fn.expand "%:p"
  end

  Bookmarks.bookmarks[fname] = true
  Bookmarks.save()

  return fname
end

function Bookmarks.remove(fname)
  if fname then fname = path.abspath(fname) end
  fname = fname or vim.fn.expand "%:p"
  if not Bookmarks.bookmarks[fname] then return end

  Bookmarks.bookmarks[fname] = nil
  Bookmarks.save()
  return fname
end

function Bookmarks.open(fname)
  fname = path.abspath(fname)
  if not Bookmarks.bookmarks[fname] then return end

  vim.cmd(":e! " .. fname)
end
