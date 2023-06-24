local lua = filetype.get 'lua'
local package_path = vim.split(package.path, ";")
local formatter_path = path.join(os.getenv "HOME", ".cargo", "bin", "stylua")
local formatter_args = array.join({
  "--call-parentheses None",
  "--collapse-simple-statement Always",
  "--line-endings Unix",
  "--column-width 80",
  "--quote-style AutoPreferDouble",
  "--indent-type Spaces",
  "--indent-width 4",
  "-",
}, " ")
local formatter_cmd = formatter_path .. ' ' .. formatter_args

lua.formatter = {formatter_cmd, stdin=true}
lua.repl = 'lua'
lua.compile = 'lua'
lua.lsp_server = {
  "lua_ls",
  config = {
    cmd = {
      path.join(
      vim.fn.stdpath "data",
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
  },
}

lua:add_autocmd {
  name = 'lua.whitespace',
  callback = function (au)
    buffer.setoption(au.buf, {shiftwidth=2, tabstop=2})
  end
}
