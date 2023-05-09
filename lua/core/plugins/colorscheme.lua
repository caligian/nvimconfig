plugin.colorscheme = {
  config = {
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
        require("rose-pine").setup(opts or self.config)
      end,
    },
    solarized = {
      config = { theme = "neovim" },
      setup = function(self)
        vim.o.background = "dark"
        require("solarized"):setup(self.config)
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
        opts = opts or self.config
        require("tokyonight").setup(self.config)
        vim.cmd ":color tokyonight"
      end,
    },
  },
  setup = function(self, config)
    local name = user.colorscheme
    if is_callable(name) then
      user.colorscheme(config)
    elseif is_string(name) and self.config[name] then
      self.config[name]:setup(config)
    else
      self.config.tokyonight:setup()
    end
  end,
}
