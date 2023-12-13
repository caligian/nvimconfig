local colorscheme = {}

colorscheme.config = {
  starry = {
    config = {
      starry_bold = true,
      starry_italic = true,
      starry_italic_comments = true,
      starry_italic_string = false,
      starry_italic_keywords = false,
      starry_italic_functions = true,
      starry_italic_variables = true,
      starry_contrast = true,
      starry_borders = false,
      starry_disable_background = false,
      starry_style_fix = true,
      starry_style = "moonlight",
      starry_darker_contrast = true,
      starry_deep_black = true,
      starry_set_hl = false,
      starry_daylight_switch = false,
    },
    setup = function(self, opts)
      opts = opts or {}
      opts = dict.merge(copy(self.config), opts)
      list.each(opts, function(key, value)
        vim.g[key] = value
      end)
      vim.cmd ":colorscheme starry"
    end,
  },
  rosepine = {
    config = {
      variant = "auto",
      dark_variant = "main",
      bold_vert_split = false,
      dim_nc_background = false,
      disable_background = false,
      disable_float_background = false,
      disable_italics = false,
      groups = {
        background = "base",
        panel = "surface",
        border = "highlight_med",
        comment = "muted",
        link = "iris",
        punctuation = "subtle",
        error = "love",
        hint = "iris",
        info = "foam",
        warn = "gold",
        headings = {
          h1 = "iris",
          h2 = "foam",
          h3 = "rose",
          h4 = "gold",
          h5 = "pine",
          h6 = "foam",
        },
      },
      highlight_groups = {
        ColorColumn = { bg = "rose" },
        CursorLine = { bg = "foam", blend = 10 },
        StatusLine = {
          fg = "love",
          bg = "love",
          blend = 10,
        },
      },
    },
    setup = function(self, opts)
      opts = opts or {}
      opts = dict.merge(copy(self.config), opts)
      require("rose-pine").setup(opts)
    end,
  },
  solarized = {
    setup = function(self)
      require("solarized").setup {
        highlights = function(colors, colorhelper)
          local darken = colorhelper.darken
          local lighten = colorhelper.lighten
          local blend = colorhelper.blend

          return {
            LineNr = { bg = colors.bg },
            CursorLineNr = { bg = colors.base02 },
            CursorLine = { bg = colors.base02 },
            Function = { italic = false },
            Visual = { bg = colors.cyan },
            CmpKindBorder = {
              fg = colors.base01,
              bg = colors.base04,
            },
          }
        end,
      }

      vim.cmd.color "solarized"
    end,
  },
  tokyonight = {
    config = {
      style = "storm",
      light_style = "day",
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        functions = {},
        variables = {},
        sidebars = "dark",
        floats = "dark",
      },
      sidebars = { "qf", "help" },
      day_brightness = 0.2,
      hide_inactive_statusline = false,
      dim_inactive = false,
      lualine_bold = false,
      on_colors = function(colors) end,
      on_highlights = function(highlights, colors) end,
    },
    setup = function(self, opts)
      opts = opts or {}
      opts = dict.merge(copy(self.config), opts)
      require("tokyonight").setup(opts)
      vim.cmd ":color tokyonight"
    end,
  },
}

function colorscheme:setup(name, config)
  local name = name or user.colorscheme

  if iscallable(name) then
    name(config)
  elseif isstring(name) then
    if self.config[name] then
      self.config[name]:setup(config)
    else
      local ok = pcall(vim.cmd, "color " .. name)
      if not ok then
        vim.cmd "color carbonfox"
      end
    end
  elseif istable(name) then
    local color, config = name[1], name.config
    if not self.config[color] then
      return
    end
    color = self.config[color]
    color:setup(config)
  else
    self.config.tokyonight:setup()
  end
end

colorscheme.autocmds = {
  update_line_and_sign_columns_bg = {
    "ColorScheme",
    {
      pattern = "*",
      callback = function()
        local normal = highlight("normal").guibg
        highlightset("LineNr", { guibg = normal })
        highlightset("SignColumn", { guibg = normal })
      end,
    },
  },
  update_colorcolumn_bg = {
    "ColorScheme",
    {
      pattern = "*",
      callback = function()
        local colorcol = highlight "ColorColumn"
        local normal = highlight "normal"
        local dark = isdark(normal.guibg)

        if dark then
          colorcol.guibg = lighten(normal.guibg, 15)
          colorcol.guifg = colorcol.guibg
        else
          colorcol.guibg = darken(normal.guibg, 15)
          colorcol.guibg = colorcol.guifg
        end

        highlightset("ColorColumn", colorcol)
      end,
    },
  },
  update_cursorline_colors = {
    "ColorScheme",
    {
      pattern = "*",
      callback = function()
        local cursorline = highlight "cursorline"
        local normal = highlight "normal"
        local dark = isdark(normal.guibg)

        if dark then
          cursorline.guibg = lighten(normal.guibg, 22)
          cursorline.guifg = darken(normal.guifg, 22)
        else
          cursorline.guibg = darken(normal.guibg, 22)
          cursorline.guifg = lighten(normal.guifg, 22)
        end

        highlightset("CursorLine", cursorline)
      end,
    },
  },
  visual_mode_colors = {
    "ColorScheme",
    {
      pattern = '*',
      callback = function ()
        highlightset('Visual', {guibg = '#18088d', guifg='#ffffff'})
      end
    }
  }
}

return colorscheme
