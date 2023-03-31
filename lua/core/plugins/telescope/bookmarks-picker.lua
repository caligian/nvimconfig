local T = utils.telescope
local B = Bookmarks
local config = T.ivy
local M = T.create_actions_mod()

function M.remove_bookmark(sel) 
  B.remove(sel.path or sel[1], sel.linenum) 
end

local function get_items(path)
  local has = B.list(path)
  if not has then return end

  return {
    results = has,
    entry_maker = function(entry)
      return {
        value = entry[1],
        display = sprintf("%d:%s", entry[1], entry[2]),
        ordinal = entry[1],
        linenum = entry[1],
        path = path,
      }
    end,
  }
end

return {
  get_linenum = function(path)
    assert(path, 'path expected')
    local has = get_items(path)
    if not has then return end

    return T.new(has, function(sel) B.jump(sel.path, sel.linenum) end, {
      prompt_title = "Bookmarks",
      attach_mappings = function(prompt_bufnr, map)
        map("n", "x", M.remove_bookmark)
        return true
      end,
    })
  end,

  get_linenum_remover = function(path) 
    assert(path, 'path expected')
    local has = get_items(path)
    if not has then return end

    return T.new(has, function (sel)
      B.remove(sel.path, sel.linenum)
    end, {prompt_title='Remove bookmarks'})
  end,

  get = function ()
    local has = Bookmarks.list()
    if not has then return end

    return T.new(has, function (sel)
      local path = has[1]
      if #has > 0 then
      end
    end, {
      prompt_title = 'Bookmarked files',
      attach_mappings = function (prompt_bufnr, map)
        map('n', 'x', M.remove_bookmark)
        return true
      end
    })
  end,
}
