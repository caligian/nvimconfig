user.plugins.colorscheme = {
  background = "dark",
  colorscheme = user.colorscheme,
  config = {},
}
local theme = user.plugins.colorscheme

theme.neosolarized = function()
  require("neosolarized").setup({
    comment_italics = true,
    background_set = false,
  })
end

theme["rose-pine"] = function()
  require("rose-pine").setup()
  vim.cmd("colorscheme rose-pine")
end

theme.onedark = function(config)
  V.asserttype(e, "table")
  V.asserttype(e, "boolean")

  config = config
    or {
      -- deep, warm, warmer, light, dark, darker
      style = "deep",
      transparent = false,
      term_colors = true,
      ending_tildes = false,
      cmp_itemkind_reverse = false,
      code_style = {
        comments = "italic",
        keywords = "none",
        functions = "none",
        strings = "none",
        variables = "none",
      },
      lualine = { transparent = false },
      colors = {},
      highlights = {},
      diagnostics = {
        darker = true,
        undercurl = true,
        background = true,
      },
    }

  vim.cmd("color onedark")
end

V.each({
  "tokyonight-night",
  "tokyonight-storm",
  "tokyonight-day",
  "tokyonight-moon",
}, function(c)
  theme[c] = function(config)
    config = config
      or {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        style = "storm", -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
        light_style = "day", -- The theme is used when the background is set to light
        transparent = false, -- Enable this to disable setting the background color
        terminal_colors = true, -- Configure the colors used when opening a `:terminal` in Neovim
        styles = {
          -- Style to be applied to different syntax groups
          -- Value is any valid attr-list value for `:help nvim_set_hl`
          comments = { italic = true },
          keywords = { italic = true },
          functions = {},
          variables = {},
          -- Background styles. Can be "dark", "transparent" or "normal"
          sidebars = "dark", -- style for sidebars, see below
          floats = "dark", -- style for floating windows
        },
        sidebars = { "qf", "help" }, -- Set a darker background on sidebar-like windows. For example: `["qf", "vista_kind", "terminal", "packer"]`
        day_brightness = 0.3, -- Adjusts the brightness of the colors of the **Day** style. Number between 0 and 1, from dull to vibrant colors
        hide_inactive_statusline = false, -- Enabling this option, will hide inactive statuslines and replace them with a thin border instead. Should work with the standard **StatusLine** and **LuaLine**.
        dim_inactive = false, -- dims inactive windows
        lualine_bold = false, -- When `true`, section headers in the lualine theme will be bold

        --- You can override specific color groups to use other groups or a hex color
        --- function will be called with a ColorScheme table
        ---@param colors ColorScheme
        on_colors = function(colors) end,

        --- You can override specific highlights to use other groups or a hex color
        --- function will be called with a Highlights and ColorScheme table
        ---@param highlights Highlights
        ---@param colors ColorScheme
        on_highlights = function(highlights, colors) end,
      }
    vim.cmd("color " .. c)
  end
end)

-- You have to set two keys:
-- colorscheme string Name of the theme
-- config table additional theme configuration (if theme supports it)
V.require("user.plugins.colorscheme")

local function set_colorscheme(bg)
  bg = bg or "dark"
  theme.background = bg
  local color

  if theme.background == "light" then
    color = theme.colorscheme.light
  else
    color = theme.colorscheme.dark
  end

  if theme.background == "light" or color:match("light") then
    vim.o.background = "light"
  else
    vim.o.background = "dark"
  end

  if theme[color] then
    theme[color](theme.config)
  else
    vim.cmd("colorscheme " .. color)
  end
end

local function get_themes()
  themes = vim.fn.globpath(vim.o.runtimepath, "colors/*.vim", 0, 1)
  themes = Set(themes)
  themes = Set.map(themes, function(t)
    return vim.fn.fnamemodify(t, ":t:r")
  end)
  local exclude = Set(dir.getfiles("/usr/share/nvim/runtime/colors"))
  exclude = Set.map(exclude, function(s)
    s = V.basename(s)
    s = vim.fn.fnamemodify(s, ":r")
    return s
  end)

  themes = Set.difference(themes, exclude)
  themes = List.sort(Set.values(themes))

  return themes
end

Keybinding.bind(
  {
    leader = true,
    noremap = true,
  },
  { "htL", V.partial(set_colorscheme, "light"), "Set light theme" },
  { "htD", V.partial(set_colorscheme, "dark"), "Set dark theme" },
  { "htd", set_colorscheme, "Use dark" },
  { "htl", set_colorscheme, "Use light" },
  {
    "htt",
    function()
      if theme.background == "light" then
        theme.background = "dark"
      else
        theme.background = "light"
      end
    end,
    "Toggle dark/light",
  },
  {
    "htl",
    function()
      local buf = Buffer(false, true)
      local themes = V.unshift(get_themes(), "[<CR>] Set colorscheme [l] Light bg [d] Dark bg")
      buf:setlines(0, -1, themes)
      buf:split("v")
      buf:setopt("modifiable", false)
      buf:bind(
        { noremap = true },
        { "l", V.partial(set_colorscheme, "light") },
        { "d", V.partial(set_colorscheme, "dark") },
        {
          "<CR>",
          function()
            local pos = vim.fn.getpos(".")[2]
            if pos > 1 then
              local t = buf:lines(pos - 1, pos)[1]
              if theme.background == "light" then
                theme.colorscheme.light = t
              else
                theme.colorscheme.dark = t
              end
              set_colorscheme()
            end
          end,
        }
      )

      buf:noremap("ni", "q", function()
        buf:hide()
        buf:delete()
      end)

      buf:hook("WinLeave", function()
        buf:hide()
        buf:delete()
      end)
    end,
    "Set theme",
  }
)

set_colorscheme()
