local statusline = {}

statusline.colors = {
  bg = "#000000",
  fg = "#ffffff",
  yellow = "#ECBE7B",
  cyan = "#008080",
  darkblue = "#081633",
  green = "#98be65",
  orange = "#FF8800",
  violet = "#a9a1e1",
  magenta = "#c678dd",
  blue = "#51afef",
  red = "#ec5f67",
}

function statusline:update_colors()
  local normal = highlight "Normal"
  local colors = copy(self.colors)
  colors.bg = normal.guibg or colors.bg
  colors.fg = normal.guifg or colors.fg

  local bg = colors.bg
  local fg = colors.fg

  if is_light(bg) then
    local contrast = contrast(bg, fg)
    for key, value in pairs(colors) do
      if contrast < 4 then
        colors[key] = darken(value, 30)
      else
        colors[key] = darken(value, 5)
      end
    end
    colors.bg = darken(bg, 5)
  else
    local contrast = contrast(bg, fg)
    for key, value in pairs(colors) do
      if contrast < 4 then
        colors[key] = lighten(value, 20)
      else
        colors[key] = lighten(value, 5)
      end
    end
  end

  return colors
end

function statusline:setup_evil()
  -- Eviline config for lualine
  -- Author: shadmansaleh
  -- Credit: glepnir
  local lualine = require "lualine"
  local colors = self:update_colors()

  local conditions = {
    buffer_not_empty = function()
      return vim.fn.empty(vim.fn.expand "%:t") ~= 1
    end,
    hide_in_width = function()
      return vim.fn.winwidth(0) > 80
    end,
    check_git_workspace = function()
      local filepath = vim.fn.expand "%:p:h"
      local gitdir = vim.fn.finddir(".git", filepath .. ";")
      return gitdir and #gitdir > 0 and #gitdir < #filepath
    end,
  }

  -- Config
  local config = {
    options = {
      -- Disable sections and component separators
      component_separators = "",
      section_separators = "",
      theme = {
        -- We are going to use lualine_c an lualine_x as left and
        -- right section. Both are highlighted by c theme .  So we
        -- are just setting default looks o statusline
        normal = { c = { fg = colors.fg, bg = colors.bg } },
        inactive = {
          c = { fg = colors.fg, bg = colors.bg },
        },
      },
    },
    sections = {
      -- these are to remove the defaults
      lualine_a = {},
      lualine_b = {},
      lualine_y = {},
      lualine_z = {},
      -- These will be filled later
      lualine_c = {},
      lualine_x = {},
    },
    inactive_sections = {
      -- these are to remove the defaults
      lualine_a = {},
      lualine_b = {},
      lualine_y = {},
      lualine_z = {},
      lualine_c = {},
      lualine_x = {},
    },
  }

  -- Inserts a component in lualine_c at left section
  local function ins_left(component)
    table.insert(config.sections.lualine_c, component)
  end

  -- Inserts a component in lualine_x ot right section
  local function ins_right(component)
    table.insert(config.sections.lualine_x, component)
  end

  ins_left {
    function()
      return ""
    end,
    color = { fg = colors.red }, -- Sets highlighting of component
    padding = { left = 0, right = 1 }, -- We don't need space before this
  }

  -- ins_left {
  --   -- mode component
  --   function() return "" end,
  --   color = function()
  --     -- auto change color according to neovims mode
  --     local mode_color = {
  --       n = colors.red,
  --       i = colors.green,
  --       v = colors.blue,
  --       [""] = colors.blue,
  --       V = colors.blue,
  --       c = colors.magenta,
  --       no = colors.red,
  --       s = colors.orange,
  --       S = colors.orange,
  --       [""] = colors.orange,
  --       ic = colors.yellow,
  --       R = colors.violet,
  --       Rv = colors.violet,
  --       cv = colors.red,
  --       ce = colors.red,
  --       r = colors.cyan,
  --       rm = colors.cyan,
  --       ["r?"] = colors.cyan,
  --       ["!"] = colors.red,
  --       t = colors.red,
  --     }
  --     return { fg = mode_color[vim.fn.mode()] }
  --   end,
  --   padding = { right = 1 },
  -- }

  ins_left {
    -- filesize component
    "filesize",
    cond = conditions.buffer_not_empty,
  }

  ins_left {
    "filename",
    cond = conditions.buffer_not_empty,
    color = { fg = colors.magenta, gui = "bold" },
  }

  ins_left {
    function()
      local bufnr = vim.fn.bufnr()
      local groups = user.buffers[bufnr]
      if not groups then
        return "<!>"
      end
      return sprintf("<%s>", join(keys(groups.buffer_groups), ","))
    end,
  }

  ins_left {
    "branch",
    icon = "branch:",
    color = { fg = colors.violet, gui = "bold" },
  }

  ins_left {
    function()
      return "x: %l/%L, y: %c"
    end,
  }

  -- ins_left { "location" }
  -- ins_left { "progress", color = { fg = colors.fg, gui = "bold" } }
  ins_left {
    "diagnostics",
    sources = { "nvim_diagnostic" },
    symbols = {
      error = "!!",
      warn = "!",
      info = "~",
      hint = "?",
    },
    diagnostics_color = {
      color_error = { fg = colors.red },
      color_warn = { fg = colors.yellow },
      color_info = { fg = colors.cyan },
    },
  }

  -- Insert mid section. You can make any number of sections in neovim :)
  -- for lualine it's any number greater then 2
  ins_left {
    function()
      return "%="
    end,
  }

  -- ins_left {
  --   -- Lsp server name .
  --   function()
  --     local msg = "No Active Lsp"
  --     local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
  --     local clients = vim.lsp.get_active_clients()
  --     if next(clients) == nil then
  --       return msg
  --     end
  --     for _, client in ipairs(clients) do
  --       local filetypes = client.config.filetypes
  --       if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
  --         return client.name
  --       end
  --     end
  --     return msg
  --   end,
  --   icon = " ",
  --   color = { fg = "#ffffff", gui = "bold" },
  -- }

  -- Add components to right sections
  ins_right {
    "o:encoding", -- option component same as &encoding in viml
    fmt = string.upper, -- I'm not sure why it's upper case either ;)
    cond = conditions.hide_in_width,
    color = { fg = colors.green },
  }

  ins_right {
    "diff",
    symbols = { added = "+", modified = "~", removed = "-" },
    diff_color = {
      added = { fg = colors.green },
      modified = { fg = colors.orange },
      removed = { fg = colors.red },
    },
    cond = conditions.hide_in_width,
  }

  ins_right {
    function()
      return ""
    end,
    color = { fg = colors.red },
    padding = { left = 1 },
  }

  -- Now don't forget to initialize lualine
  lualine.setup(config)
end

statusline.config = {
  evil = true,
  options = {
    icons_enabled = true,
    theme = "auto",
    component_separators = { left = "", right = "" },
    section_separators = { left = "", right = "" },
    disabled_filetypes = {
      statusline = {},
      winbar = {},
    },
    ignore_focus = {},
    always_divide_middle = true,
    globalstatus = false,
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 10,
    },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff", "diagnostics" },
    lualine_c = { "filename" },
    lualine_x = { "encoding", "fileformat", "filetype" },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { "filename" },
    lualine_x = { "location" },
    lualine_y = {},
    lualine_z = {},
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {},
}

statusline.autocmds = {
  update_statusline_colors = {
    "ColorScheme",
    {
      pattern = "*",
      callback = function()
        statusline:setup()
      end,
    },
  },
}

function statusline:setup()
  if self.config.evil then
    self:setup_evil()
  else
    local config = copy(self.config)
    config.evil = false
    require("lualine").setup(self.config)
  end
end

return statusline
