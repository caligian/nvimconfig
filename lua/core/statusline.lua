local function set_statusline(...)
  local statusline = { ... }
  vim.cmd("set statusline=")

  V.each(statusline, function(line)
    local user_n, s = unpack(line)
    s = s:gsub(" +", "\\ ")
    s = sprintf("%%%d*%s%%*", user_n, s)
    vim.cmd("set statusline +=" .. s)
  end)
end

local function get_statusline_bg()
  local normal = V.highlight("Normal")
  local defaults = { guibg = "#002b36", guifg = "#ffffff" }
  if table.isblank(normal) then
    normal = defaults
  end
  table.lmerge(normal, defaults)

  local active = {
    guibg = V.darken(normal.guibg, "10"),
    guifg = V.lighten(normal.guifg, "20"),
  }

  return active, normal
end

local function highlight_statusline(...)
  local active = get_statusline_bg()

  V.ieach({ ... }, function(idx, fg)
    fg = fg or "#efefef"
    vim.cmd(sprintf("hi User%d guibg=%s guifg=%s", idx, active.guibg, fg))
  end)
end

local function get_colors(...)
  local default = "#efefef"
  local c = {}

  for idx, val in ipairs({ ... }) do
    local hi = V.highlight(val)
    local fg = hi.guifg or default
    c[idx] = fg
  end

  return c
end

local function set_background()
  local active, inactive = get_statusline_bg()
  V.highlightset("StatusLine", active)
  V.highlightset("StatusLineNC", inactive)
end

local function setup()
  local colors = get_colors(unpack({
    "Variable",
    "Function",
    "Comment",
    "String",
    "DiagnosticWarn",
    "DiagnosticInfo",
    "Boolean",
    "Comment",
    "Comment",
  }))

  local statusline = {
    -- bufnr
    { 6, " %n" },

    -- readonly?
    { 2, " %R" },

    -- filetype/qflist
    { 3, " %y" },
    { 3, " %q" },

    -- abspath
    { 4, "%<%F" },

    -- modified?
    { 5, "%m" },

    -- line/total lines|column
    { 6, " %=%l/%L\\|%c " },
  }

  set_statusline(unpack(statusline))
  highlight_statusline(unpack(colors))
  set_background()
end

Autocmd("ColorScheme", {
  pattern = "*",
  callback = setup,
  name = "update_statusline_colors",
})

setup()
