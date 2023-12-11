local go = filetype.get "go"

go.lsp_server = "gopls"
go.compile = "go run"
go.test = "go test"

local function run_and_split(cmd, append_bufname)
  return function()
    if append_bufname then
      cmd = cmd .. " " .. buffer.name()
    end

    run_command(cmd, cmd .. "_stdout", "s")
  end
end

go.mappings = {
  opts = { prefix = "m", noremap = true, leader = true },
  clean = { "c", run_and_split "go clean", { desc = "clean" } },
  deps = { "d", run_and_split "go get", { desc = "fetch deps" } },
  list = { "l", run_and_split "go list", { desc = "list modules/packages" } },
  vet = { "v", run_and_split "go vet", { desc = "vet source" } },
}

go.formatter = { "gofmt -s -e", append_filename = true, stdin = true }

return go
