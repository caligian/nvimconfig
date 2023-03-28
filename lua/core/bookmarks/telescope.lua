require "core.bookmarks.marks"

local T = utils.telescope
local M = T.create_actions_mod()

local function list_bookmarks() return table.keys(Marks.marks) end

local function list_marks(path)
  return {
    results = Marks.list(path),
    entry_maker = function(entry)
      return {
        value = entry[1],
        display = sprintf("%d: %s", entry[1], entry[2]),
        ordinal = entry[1],
        path = path,
        linenum = entry[1],
      }
    end,
  }
end

local function run_marks_picker(path) 
  path = path or vim.api.nvim_buf_get_name(vim.fn.bufnr())
  T.new(
    list_marks(path or vim.fn.bufname()),
    function (sel)
      Marks.jump(sel.path, sel.linenum)
    end,
    {
      prompt_title = 'Current path marks'
    }
  ):find()
end

local function run_bookmarks_picker()
  T.new(list_bookmarks(), nil, {prompt_title='Bookmarks'}):find()
end
