local Bookmark = Class.new "Bookmark"
local exception = Exception "BookmarkException"
exception.invalid_path = "expected valid buffer/path"

local function resolve_path(p)
  validate { path = { is { "string", "number" }, p } }

  if p == 0 then
    p = vim.fn.bufnr()
  end
  local is_buffer = vim.fn.bufexists(p) ~= 0
  local is_file = is_a.string(p) and path.exists(p)

  if not is_buffer and not is_file then
    return
  end

  if is_buffer then
    local bufnr = vim.fn.bufnr()
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if #bufname == 0 then
      return
    end

    if path.isdir(bufname) then
      p = {
        dir = true,
        path = bufname,
      }
    else
      local loaded = vim.fn.bufloaded(bufnr) == 1
      if not loaded then
        return
      end
      local listed = vim.api.nvim_buf_get_option(bufnr, "buflisted")
      if not listed then
        return
      end
      p = {
        bufnr = bufnr,
        path = bufname,
        dir = false,
        file = true,
        lines = {},
      }
    end
  elseif path.isdir(p) then
    p = {
      dir = true,
      file = false,
      path = path.abspath(p),
    }
  else
    p = {
      dir = false,
      file = true,
      path = p,
      lines = {},
    }
  end

  return p
end

function Bookmark:init(p)
  p = resolve_path(p)
  if not p then
    error("Invalid path supplied " .. p)
  end
  dict.merge(self, p)
end

local function file_line_count(p)
  return #(file.read(p):split "\n")
end

local function buffer_line_count(bufnr)
  return vim.api.nvim_buf_line_count(bufnr)
end

local function file_line(p, line)
  return file.read(p):split("\n")[line]
end

local function buffer_line(bufnr, line)
  return vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1]
end

function Bookmark:update_context()
  if self.dir then
    return
  end
  if dict.isblank(self.lines) then
    return
  end

  local n
  if self.bufnr then
    n = buffer_line_count(self.bufnr)
  elseif self.path then
    n = file_line_count(self.path)
  end

  dict.each(self.lines, function(line, _)
    if line > n or line < 1 then
      self.lines[line] = nil
    else
      self.lines[line] = self.bufnr and buffer_line(self.bufnr, line) or file_line(line)
    end
  end)
end

function Bookmark:remove(line)
  local obj = self.lines[isa("number", line)]
  if obj then
    self.lines[line] = nil
    return obj
  end
  return false
end

function Bookmark:list(telescope)
  if self:isdir() then
    return false, self.path .. " is a directory"
  elseif dict.isblank(self.lines) then
    return false, self.path .. " does not have lines"
  end

  if telescope then
    return {
      results = dict.items(self.lines),
      entry_maker = function(entry)
        return {
          ordinal = entry[1],
          line = entry[1],
          context = entry[2],
          display = sprintf("%d: %s", entry[1], entry[2]),
          path = self.path,
          bufnr = self.bufnr,
          dir = self.dir,
          file = self.file,
        }
      end,
    }
  end

  return self.lines
end

function Bookmark:add(line)
  line = line or "."
  validate.line(function(x)
    local msg = "'.' for current line or line number"
    local ok = x == "." or is_a.number(x)
    if not ok then
      return ok, msg
    end
    return true
  end, line)

  local winid = vim.fn.bufwinid(self.bufnr)
  if line == "." then
    if winid ~= -1 then
      line = vim.api.nvim_buf_call(self.bufnr, function()
        return vim.fn.getpos(".")[2]
      end)
    else
      return false, self.path .. " is not visible"
    end
  elseif self.dir then
    return false, self.path .. " is a directory"
  end

  local n = self.bufnr and buffer_line_count(self.bufnr) or file_line_count(self.path)

  if line > n or line < 1 then
    return false, "must be 1 <= linenum <= path_line_count"
  end

  self.lines[line] = self.bufnr and buffer_line(self.bufnr, line) or file_line(self.path)

  return self.lines[line]
end

function Bookmark:is_invalid(line)
  if not line then
    if not path.exists(self.path) then
      return true
    end
    return false
  end

  return self.lines[line] and line or false
end

function Bookmark:isdir()
  self.dir = path.isdir(self.path)
  return self.dir
end

function Bookmark:jump(line, split)
  if self.dir then
    vim.cmd(sprintf(":Lexplore %s | vert size 40", sel.path))
  elseif not self.bufnr then
    self = self.path
    if split == "s" then
      vim.cmd(":split " .. self)
    elseif split == "v" then
      vim.cmd(":vsplit " .. self)
    elseif split == "t" then
      vim.cmd(":tabnew " .. self)
    else
      vim.cmd(":e " .. self)
    end
    if self.lines and self.lines[line] then
      vim.cmd(":normal! " .. line .. "G")
    end
  elseif self.bufnr then
    local bufnr = self.bufnr
    if split == "s" then
      vim.cmd(":split | b " .. bufnr)
    elseif split == "v" then
      vim.cmd(":vsplit | b " .. bufnr)
    elseif split == "t" then
      vim.cmd(":tabnew | b " .. bufnr)
    else
      vim.cmd(":b " .. bufnr)
    end
    if self.lines and self.lines[line] then
      vim.cmd(":normal! " .. line .. "G")
    end
  elseif self.dir then
    vim.cmd(sprintf(":Lexplore %s | vert resize 40", self.path))
  end
end

function Bookmark:create_picker(remover)
  local _ = utils.telescope.load()
  local mod = _.create_actions_mod()
  local ls = self:list(true)
  if not ls then
    return
  end
  local default_action

  if remover then
    default_action = function(prompt_bufnr)
      array.each(_.get_selected(prompt_bufnr), function(sel)
        self:remove(sel.line)
      end)
    end
  else
    default_action = function(prompt_bufnr)
      local sel = _.get_selected(prompt_bufnr)[1]
      self:jump(sel.line, "v")
    end
  end

  function mod.remove(sel)
    self:remove(sel.line)
  end
  function mod.split(sel)
    self:jump(sel.line, "s")
  end
  function mod.tabnew(sel)
    self:jump(sel.line, "t")
  end
  function mod.vsplit(sel)
    self:jump(sel.line, "v")
  end

  return _.new(ls, {
    default_action,
    { "n", "x", mod.remove },
    { "n", "s", mod.split },
    { "n", "v", mod.vsplit },
    { "n", "t", mod.tabnew },
  }, {
    prompt_title = remover and ("Remove marks: " .. self.path) or ("Manage marks: " .. self.path),
  })
end

return Bookmark
