local function load_with_user(name)
  local ok, msg = pcall(require, "core.defaults." .. name)
  requirex("user." .. name)

  if ok and isa.callable(msg) then
    msg()
  end
end

local function load_all()
  local dest = path.join(user.dir, "lua", "core", "defaults")
  local files = dir.getallfiles(dest)

  list.each(files, function(x)
    if x:match "init" or x:match "buffer_group" then
      return
    end

    x = path.basename(x)
    if not strmatch(x, "lua$", "^[a-zA-Z0-9_-]+$") then
      return
    end

    x = x:gsub("%.lua$", "")

    load_with_user(x)
  end)
end

load_all()
