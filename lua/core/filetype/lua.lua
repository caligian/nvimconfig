local package_path = vim.split(package.path, ";")
local formatter_path =
  path.join(os.getenv "HOME", ".cargo", "bin", "stylua")
local formatter_cmd = formatter_path
  .. " "
  .. join({
    "--call-parentheses None",
    "--collapse-simple-statement Never",
    "--line-endings Unix",
    "--column-width 60",
    "--quote-style AutoPreferDouble",
    "--indent-type Spaces",
    "--indent-width 2",
  }, " ")

return {
  bo = {
    shiftwidth = 2,
    tabstop = 2,
  },

  formatter = {
    stdin = true,
    buffer = formatter_cmd .. " -",
    workspace = { formatter_cmd .. " {path}" },
    dir = { formatter_cmd .. " {path}" },
  },

  compile = {
    buffer = "luajit %path",
    workspace = function(ws)
      local kids =
        split(vim.fn.glob(ws .. "/*.rockspec"), "\n")
      local cmd = "luarocks --local build "
        .. (kids[1] or "")
      return cmd
    end,
  },

  repl = {
    buffer = "luajit",
    workspace = "luajit",
    dir = "luajit",
  },

  server = {
    "lua_ls",
    config = {
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
            disable = {
              "lowercase-global",
              "undefined-global",
            },
          },
        },
      },
    },
  },
}
