local lua = filetype "lua"
local package_path = vim.split(package.path, ";")
local formatter_path = path.join(os.getenv "HOME", ".cargo", "bin", "stylua")
local formatter_cmd = formatter_path

local default_args = {
  "--call-parentheses None",
  "--collapse-simple-statement Never",
  "--line-endings Unix",
  "--column-width 100",
  "--quote-style AutoPreferDouble",
  "--indent-type Spaces",
  "--indent-width 2",
  "-",
}

lua.formatter_local_config_path = { "stylua.toml", ".stylua.toml" }

lua.formatter = {
  formatter_cmd,
  args = default_args,
  append_filename = true,
  stdin = true,
}

lua.dir_formatter = {
  formatter_cmd,
  args = default_args,
  append_dirname = true,
}

lua.repl = {
  { "luajit", workspace = "luajit" },
}

lua.compile = {
  {
    "luajit %s",
  },
}

lua.lsp_server = {
  "lua_ls",
  cmd = {
    path.join(
      vim.fn.stdpath "data",
      "lsp-servers",
      "lua-language-server",
      "bin",
      "lua-language-server"
    ),
  },
  settings = {
    Lua = {
      path = package_path,
      runtime = {
        version = "Lua 5.1",
      },
      workspace = {
        library = package_path,
      },
      telemetry = {
        enable = false,
      },
      diagnostics = {
        severity = { { ["undefined-global"] = false } },
        disable = { "lowercase-global", "undefined-global" },
      },
    },
  },
}

lua.autocmds = {
  whitespace = function(au)
    buffer.set_option(au.buf, { shiftwidth = 2, tabstop = 2 })
  end,
}

lua.actions = {
  workspace = {
    default = build,
    build = build,
  },
}

return lua
