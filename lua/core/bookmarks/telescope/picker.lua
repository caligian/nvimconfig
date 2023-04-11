require "core.bookmarks.bookmarks"

local B = Bookmarks
local T = utils.telescope
local _ = T.load()
B.telescope = {}
local M = B.telescope

function M.list_buffers()
  return table.grep(
    table.map(vim.fn.getbufinfo(), function(x)
      local bufnr = x.bufnr
      local name = #x.name > 0 and x.name or false
      local loaded = x.loaded == 1
      local listed = x.listed == 1
      local test = name and loaded and listed
      if not test then
        return false
      end

      return vim.api.nvim_buf_get_name(bufnr)
    end),
    function(x)
      return x or false
    end
  )
end

function M.get_finder_table(p)
  local items = B.list(p)
  if not items or #table.keys(items) == 0 then
    return false
  end
  return {
    results = table.items(items),
    entry_maker = function(entry)
      return {
        value = entry[1],
        display = sprintf("%d:%s", entry[1], entry[2]),
        ordinal = entry[1],
        line = entry[1],
        path = p,
      }
    end,
  }
end

function M.get_marks_picker(p, split)
  local t = M.get_finder_table(p)
  if not t then
    return
  end
  local mod = T.create_actions_mod()
  mod.jump = function(sel)
    B.jump(sel.path, sel.line, split)
  end
  mod.remove = function(sel)
    B.remove(sel.path, sel.line)
  end
  mod.split = function(sel)
    B.jump(sel.path, sel.line, "s")
  end
  mod.vsplit = function(sel)
    B.jump(sel.path, sel.line, "v")
  end
  mod.tabnew = function(sel)
    B.jump(sel.path, sel.line, "t")
  end

  return T.new(t, {
    mod.jump,
    { "n", "x", mod.remove },
    { "n", "s", mod.split },
    { "n", "v", mod.vsplit },
    { "n", "t", mod.tabnew },
  }, {
    prompt_title = "Buffer bookmarks",
  })
end

function M.get_marks_remover_picker(p)
  local t = M.get_finder_table(p)
  if not t then
    return
  end
  local mod = T.create_actions_mod()
  mod.remove = function(sel)
    B.remove(sel.path, sel.line)
  end
  return T.new(t, { mod.remove }, { prompt_title = "Remove buffer bookmarks" })
end

function M.get_picker(p, remove)
  if p and remove then
    return M.get_marks_remover_picker(p)
  end
  if p then
    return M.get_marks_picker(p)
  end
  local items = B.list()
  if not items then
    return false
  end
  local mod = T.create_actions_mod()
  local remove = function(p)
    local picker = M.get_marks_remover_picker(p)
    if picker then
      picker:find()
    else
      B.remove(p)
    end
  end
  local jump = function(p, split)
    local picker = M.get_marks_picker(p, split)
    if picker then
      picker:find()
    else
      B.jump(p, split)
    end
  end
  local split = function(p)
    jump(p, "s")
  end
  local vsplit = function(p)
    jump(p, "v")
  end
  local tabnew = function(p)
    jump(p, "t")
  end
  mod.jump = function(sel)
    jump(sel[1])
  end
  mod.split = function(sel)
    split(sel[1])
  end
  mod.vsplit = function(sel)
    vsplit(sel[1])
  end
  mod.tabnew = function(sel)
    tabnew(sel[1])
  end
  mod.remove = function(sel)
    remove(sel[1])
  end

  return T.new(items, {
    mod.jump,
    { "n", "s", mod.split },
    { "n", "v", mod.vsplit },
    { "n", "t", mod.tabnew },
    { "n", "x", mod.remove },
  }, { prompt_title = "All bookmarks" })
end

function M.run_marks_picker(p)
  local m = M.get_marks_picker(p)
  if m then
    m:find()
  end
end

function M.run_marks_remover_picker(p)
  local m = M.get_marks_remover_picker(p)
  if m then
    m:find()
  end
end

function M.run_picker(p, remover)
  local m = M.get_picker(p, remover)
  if m then
    m:find()
  end
end

return M
