local go = {}

go.server = "gopls"
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
  clean = {
    "n",
    "<leader>mc",
    run_and_split "go clean",
    { desc = "clean" },
  },
  deps = {
    "n",
    "<leader>d",
    run_and_split "go get",
    { desc = "fetch deps" },
  },
  list = {
    "n",
    "<leader>ml",
    run_and_split "go list",
    { desc = "list modules/packages" },
  },
  vet = {
    "n",
    "<leader>mv",
    run_and_split "go vet",
    { desc = "vet source" },
  },
}

go.formatter = { buffer = "gofmt -s -e", stdin = true }

return go

