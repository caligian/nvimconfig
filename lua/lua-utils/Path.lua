require "lua-utils.utils"
require "lua-utils.table"

local lpeg = require "lpeg"
local lfs = require "lfs"
Path = dict.merge(module(), { lfs })
Path.ln = Path.link
Path.stat = Path.attributes
Path.lnstat = Path.symlinkattributes
Path.lockdir = Path.lock_dir
Path.cd = Path.chdir
Path.cwd = Path.currentdir
Path.lock_dir = nil

local lpeg = require 'lpeg'

function Path.split(p)
  local P = lpeg.P
  local C = lpeg.C
  local Ct = lpeg.Ct
  local V = lpeg.V
  local Cp = lpeg.Cp()
  local B = lpeg.B

  local path_sep = Path.sep()
  local escaped = P('\\' .. path_sep)
  local sep = B(1 - escaped) * P(path_sep)
  local elem = C((1 - sep) ^ 1)
  local pat =  Ct(C(P"/" ^ 0) * elem * (sep * elem) ^ 0)
  local found = pat:match(p) 

  if not found then
    return
  end

  return found
end

function Path.join(...)
  local iswin = package.path:match "\\"
  local p =  {...}
  local sep = iswin and '\\' or '/' 

  if p[1] == sep then
    if #p == 1 then
      return sep
    else
      p[1] = ''
    end
  end

  if iswin then
    return join(p, "\\")
  else
    return join(p, '/')
  end
end

function Path.sep()
  return package.path:match "\\" and "\\" or "/"
end

function Path.is(p, mode)
  assert_is_a.string(mode)

  local attribs, msg = Path.attributes(p)

  if not attribs then
    return false, msg
  end

  return attribs.mode == mode
end

function Path.exists(p)
  return Path.stat(p) ~= nil
end

function Path.is_namedpipe(p)
  return Path.is(p, "named pipe")
end

function Path.is_dir(p)
  return Path.is(p, "directory")
end

function Path.is_pipe(p)
  return Path.is(p, "pipe")
end

function Path.is_char(p)
  return Path.is(p, "char device")
end

function Path.is_block(p)
  return Path.is(p, "block device")
end

function Path.is_file(p)
  return Path.is(p, "file")
end

function Path.is_socket(p)
  return Path.is(p, "socket")
end

function Path.attrib(p, attrib)
  local attribs, msg = lfs.attributes(p)
  if not attribs then
    return attribs, msg
  end

  return attribs[attrib]
end

function Path.ctime(p)
  return Path.attrib(p, "change")
end

function Path.mtime(p)
  return Path.attrib(p, "modification")
end

function Path.atime(p)
  return Path.attrib(p, "access")
end

function Path.nlink(p)
  return Path.attrib(p, "nlink")
end

function Path.uid(p)
  return Path.attrib(p, "uid")
end

function Path.gid(p)
  return Path.attrib(p, "gid")
end

function Path.dev(p)
  return Path.attrib(p, "dev")
end

function Path.rdev(p)
  return Path.attrib(p, "rdev")
end

function Path.inode(p)
  return Path.attrib(p, "ino")
end

function Path.size(p)
  return Path.attrib(p, "size")
end

function Path.permissions(p)
  return Path.attrib(p, "permissions")
end

function Path.blksize(p)
  return Path.attrib(p, "blksize")
end

Path.blocksize = Path.blksize

function Path.blocks(p)
  return Path.attrib(p, "blocks")
end

--- ls [-p] <path>
--- @param p string dirpath
--- @param show_dirs? boolean add '/' at the end of dirs
--- @return string[]
function Path.ls(p, show_dirs)
  if not Path.is_dir(p) then
    return
  end

  local out = {}
  p = p:gsub('/$', '')

  for f in Path.dir(p) do
    if f ~= "." and f ~= ".." then
      f = Path.join(p, f)

      if show_dirs then
        if Path.is_dir(f) then
          f = Path.join(f, '')
        end
      end

      out[#out + 1] = f
    end
  end

  return out
end

Path.children = Path.ls

function Path.getdirs(p)
  local fs = Path.ls(p)
  if not fs then
    return
  end

  p = p:gsub("[/\\]$", "")

  return list.filter(fs, function(x)
    x = p .. Path.sep() .. x
    if Path.is_dir(x) then
      return true
    end
  end, function(x)
    return p .. Path.sep() .. x
  end)
end

function Path.getfiles(p)
  local fs = Path.ls(p)
  if not fs then
    return
  end

  p = p:gsub("[/\\]$", "")

  return list.filter(fs, function(x)
    x = p .. Path.sep() .. p
    if not Path.is_dir(x) then
      return true
    end
  end, function(x)
    return p .. Path.sep() .. x
  end)
end

function Path.read(p)
  if not Path.is_file(p) then
    return
  end

  local fh = io.open(p, "r")
  if not fh then
    return
  end

  local lines = fh:read "*a"
  fh:close()

  return lines
end

function Path.write(p, lines)
  local fh = io.open(p, "w")
  if not fh then
    return
  end

  assert_is_a(lines, union("string", "table"))
  lines = is_table(lines) and join(lines, "\n") or lines

  fh:write(lines)
  fh:close()

  return #lines
end

function Path:__call(...)
  local p = Path.join(...)
  if not Path.exists(p) then
    return
  end

  return p
end

function Path.dirname(p)
  p = Path.split(p)

  if not p then
    return
  end

  local path_sep = Path.sep() 
  if #p == 1 then
    return false
  end

  p[#p] = nil
  return Path.join(unpack(p))
end

function Path.basename(p)
  local last_sep
  local sep = Path.sep()

  if not p:match(sep) then
    return p
  end

  if sep == "\\" then
    for i = #p, 1, -1 do
      if p:sub(i, i) == sep then
        last_sep = i
        break
      end
    end
  else
    for i = #p, 2, -1 do
      local a = p:sub(i, i)
      local b = p:sub(i - 1, i - 1)

      if a == "/" and b ~= "\\" then
        last_sep = i
        break
      end
    end
  end

  return p:sub(last_sep + 1, #p)
end

function Path.ext(p)
  if not p:match "%." then
    return
  end

  local basename = Path.basename(p)
  if not basename then
    return
  end

  return basename:match "%.([^.]+)$"
end

Path.extension = Path.ext

function Path.abspath(p, exists)
  if not Path.exists(p) and exists then
    return
  elseif p:match "^/" or p:match "^[A-Za-z0-9_]+:\\" then
    return p
  elseif p:match("^%." .. Path.sep()) then
    p = p:sub(3)
  elseif p:match("^%.%." .. Path.sep()) then
    p = Path.dirname(p)
  end

  local cwd = Path.cwd()
  if p == "." then
    return cwd
  elseif p == ".." then
    return Path.dirname(p)
  elseif p:match(cwd) then
    return p
  end

  p = p:gsub("[/\\]$", "")
  return Path.join(cwd, p)
end

function Path.is_abs(p, exists)
  if not Path.exists(p) and exists then
    return
  elseif p:match "^/" or p:match "^[A-Za-z0-9_]+:\\" then
    return p
  end
end

function Path.relpath(p, exists)
  if exists and not Path.exists(p) then
    return
  elseif p:sub(1, 2) == "./" then
    return p
  end

  local cwd = Path.cwd()
  if cwd == p then
    return "./"
  else
    local pat = lpeg.P(cwd) * lpeg.C(lpeg.P(1) ^ 0)
    local found = pat:match(p)
    return "." .. found
  end
end

Path.delete = os.remove
Path.rm = Path.delete
