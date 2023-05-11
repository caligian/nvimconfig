plugin.illuminate = {
  config = {
    -- providers: provider used to get references in the buffer, ordered by priority
    providers = {
      "lsp",
      "treesitter",
    },
    delay = 300,
    filetype_overrides = {},
    filetypes_denylist = {
      "dirvish",
      "TelescopePrompt",
      "netrw",
      "i3config",
      "fugitive",
      "help",
      "txt",
      "text",
      "startuptime",
      "latex",
      "markdown",
      "norg",
    },
    filetypes_allowlist = {},
    modes_denylist = {},
    modes_allowlist = {},
    providers_regex_syntax_denylist = {},
    providers_regex_syntax_allowlist = {},
    under_cursor = true,
    large_file_cutoff = nil,
    large_file_overrides = nil,
    min_count_to_highlight = 1,
  },

  setup = function(self)
    require("illuminate").configure(self.config)
  end,
}
