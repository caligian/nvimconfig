-- local Bookmark = require "core.bookmarks.Bookmark"
local Bookmark = (loadfile "Bookmark.lua")()
Bookmarks = Bookmarks or {}
Bookmarks.BOOKMARKS = Bookmarks.BOOKMARKS or {}
user.bookmarks = Bookmarks.BOOKMARKS

function Bookmarks.exists(p) return Bookmarks.BOOKMARKS[p] or false end

local function get_call(p, f)
  local obj = Bookmarks.exists(p)
  if not obj then return end

  return function(line) return f(obj, line) end
end

function Bookmarks.add(p, line)
  local obj = Bookmarks.exists(p)
  local ok, msg

  if not obj then
    obj = Bookmark(p)
    Bookmarks.BOOKMARKS[obj.path] = obj
    Bookmarks.BOOKMARKS[p] = obj
  end

  ok, msg = obj:add(line)
  if not ok then error(msg) end

  return obj
end

function Bookmarks.remove(p, line)
  if not line then
    if Bookmarks.BOOKMARKS[p] then
      local obj = Bookmarks.BOOKMARKS[p]
      Bookmarks.BOOKMARKS[p] = nil
      Bookmarks.BOOKMARKS[obj.path] = nil
      return obj
    end
    return false
  end

  local ok = get_call(p, function(obj, line) obj:remove(line) end)
  if ok then return ok(line) end
  return false
end

function Bookmarks.update_context(p)
  if not p then
    dict.each(Bookmarks.BOOKMARKS, function(_, obj) obj:update_context() end)
    return true
  end

  local ok = get_call(p, function(obj) obj:update_context() end)
  if ok then return ok() end
  return false
end

function Bookmarks.clean()
  dict.each(Bookmarks.BOOKMARKS, function(p, obj) 
    if is_a.number(p)  then
      if not path.exists(obj.path) then
        Bookmarks.BOOKMARKS[p] = nil
        Bookmarks.BOOKMARKS[obj.path] = nil
      end
    elseif not path.exists(p) then
      Bookmarks.BOOKMARKS[p] = nil
    else
      obj:update_context()
    end
  end)
end

function Bookmarks.list(p, telescope)
  Bookmarks.clean()

  if dict.isblank(Bookmarks.BOOKMARKS) then return end

  if not p then
    if not telescope then
      return array.map(
        array.grep(table.keys(Bookmarks.BOOKMARKS), function (x)
          return is_a.number(x) ~= true
        end),
        function (x)
          return Bookmarks.BOOKMARKS[x]:list() or false
        end
      )
    end
    return {
      results = array.grep(dict.keys(Bookmarks.BOOKMARKS), function (x)
        return is_a.number(x) ~= true
      end),
      entry_maker = function(entry)
        return {
          ordinal = -1,
          value = entry,
          display = entry,
          path = entry,
        }
      end,
    }
  end

  local ok = get_call(p, function(obj) return obj:list(true) end)
  if ok then
    return ok()
  else
    return false
  end
end

function Bookmarks.create_main_picker(remover)
  local ls = Bookmarks.list(false, true)
  if not ls then return end
  local _ = utils.telescope.load()
  local mod = _.create_actions_mod()

  local function remove(sel)
    if sel.dir then
      Bookmarks.BOOKMARKS[sel.path] = nil
    else
      local mark = Bookmarks.exists(sel.path)
      if dict.isblank(mark.lines) then
        Bookmarks.BOOKMARKS[sel.path] = nil
      else
        mark:create_picker(true):find()
      end
    end
  end

  function mod.remove(sel)
    remove(sel)
  end

  local function default_action(prompt_bufnr)
    local sel = _.get_selected(prompt_bufnr)
    if remover then
      array.each(sel, remove)
    elseif sel.dir then
      sel = sel[1]
      vim.cmd(sprintf(":Lexplore %s | vert resize 40", sel.path))
    else
      sel = sel[1]
      local obj = Bookmarks.exists(sel.path)
      if dict.isblank(obj.lines) then
        self:jump(false, "v")
      else
        local picker = obj:create_picker()
        if picker then picker:find() end
      end
    end
  end

  local prompt_title
  if remover then
    prompt_title = "Remove bookmarks"
  else
    prompt_title = "Manage bookmarks"
  end

  return _.new(ls, {
    default_action,
    { "n", "x", mod.remove },
  }, { prompt_title = prompt_title })
    
end

function Bookmarks.create_picker(p, remover)
  local exists = Bookmarks.exists(p)
  if exists then return exists:create_picker(remover) end
end
