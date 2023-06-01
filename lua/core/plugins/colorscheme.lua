plugin.colorscheme = {
  config = {
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
      setup = function (self, opts)
        opts = opts or {}
        opts = dict.merge(utils.copy(self.config), opts)
        dict.each(opts, function (key, value) vim.g[key] = value end)
        vim.cmd ':colorscheme starry'
      end
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
          StatusLine = { fg = "love", bg = "love", blend = 10 },
        },
      },
      setup = function(self, opts)
        opts = opts or {}
        opts = dict.merge(utils.copy(self.config), opts)
        require("rose-pine").setup(opts)
      end,
    },
    solarized = {
      config = { theme = "neovim" },
      setup = function(self, opts)
        opts = opts or {}
        opts = dict.merge(utils.copy(self.config), opts)
        vim.o.background = "dark"
        require("solarized"):setup(opts)
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
        opts = dict.merge(utils.copy(self.config), opts)
        require("tokyonight").setup(opts)
        vim.cmd ":color tokyonight"
      end,
    },
  },
  autocmds = {
    update_colorcolumn_bg = {'ColorScheme', {
      pattern = '*',
      callback = function ()
        local colorcol = utils.hi 'ColorColumn'
        local normal = utils.hi 'normal'
        local dark = utils.isdark(normal.guibg)

        if dark then
          colorcol.guibg = utils.lighten(normal.guibg, 15)
          colorcol.guifg = colorcol.guibg
        else
          colorcol.guibg = utils.darken(normal.guibg, 15)
          colorcol.guibg = colorcol.guifg
        end

        utils.highlightset('ColorColumn', colorcol)
      end,
    }},
    update_cursorline_colors = {'ColorScheme', {
      pattern = '*',
      callback = function ()
        local cursorline = utils.hi 'cursorline'
        local normal = utils.hi 'normal'
        local dark = utils.isdark(normal.guibg)

        if dark then
          cursorline.guibg = utils.lighten(normal.guibg, 22)
          cursorline.guifg = utils.darken(normal.guifg, 22)
        else
          cursorline.guibg = utils.darken(normal.guibg, 22)
          cursorline.guifg = utils.lighten(normal.guifg, 22)
        end

        utils.highlightset('CursorLine', cursorline)
      end,
    }}
  },
  on_attach = function(self, config)
    local name = user.colorscheme
    if is_callable(name) then
      user.colorscheme(config)
    elseif is_string(name)  then
      if self.config[name] then
        self.config[name]:setup(config)
      else
        local ok = pcall(vim.cmd, 'color ' .. name)
        if not ok then vim.cmd 'color carbonfox' end
      end
    elseif is_table(name) then
      local color, config = name[1], name.config
      if not self.config[color] then return end
      color = self.config[color]
      color:setup(config)
    else
      self.config.tokyonight:setup()
    end
  end,
}
