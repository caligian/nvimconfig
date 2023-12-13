local elixir = {}

local function isproject(current_dir)
  local prev_dir = vim.fn.fnamemodify(current_dir, ":h")
  local ls = dir.getallfiles(prev_dir)
  local check = path.join(prev_dir, "mix.exs")

  for i = 1, #ls do
    if string.match(ls[i], check) then
      return true
    end
  end

  return false
end

elixir.repl = {
  buffer = "iex",
  workspace = "iex",
}

elixir.formatter = {
  buffer = "mix format - ",
  stdin = true,
}

elixir.compile = {
  buffer = "elixir {path}",
  workspace = "mix run",
}

elixir.test = {
  workspace = "mix test",
}

elixir.server = {
  "elixirls",
  config = {
    cmd = {
      path.join(
        user.data_dir,
        "lsp-servers",
        "elixir-ls",
        "scripts",
        "language_server.sh"
      ),
    },
  },
}

elixir.mappings = {
  compile_and_run_buffer_in_workspace = {
    "n",
    "<leader>rc",
    function()
      local bufnr = buffer.bufnr()
      local x = repl(buffer.bufnr(), { workspace = true })
      if x then
        x:send(sprintf('c("%s")', buffer.name()))
      end
    end,
    { desc = "compile and run buffer" },
  },

  compile_and_run_buffer = {
    "n",
    "<localleader>rc",
    function()
      local bufnr = buffer.bufnr()
      local x = repl(buffer.bufnr(), { buffer = true })
      if x then
        x:send(sprintf('c("%s")', buffer.name()))
      end
    end,
    { desc = "compile and run buffer" },
  },
}

return elixir
