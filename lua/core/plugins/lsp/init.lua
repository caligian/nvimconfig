local lsp = user.lsp
lsp.capabilties = require("cmp_nvim_lsp").default_capabilities()

-- Turn off annoying virtual text
lsp.diagnostic = {
  virtual_text = false,
  underline = false,
  update_in_insert = false,
}

--
function lsp.on_attach(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  if not table.contains(Lang.langs, vim.bo.filetype, "formatters") then
    require("lsp-format").on_attach(client)
  end

  -- Setup keybindings
  Keybinding.bind(
    { buffer = bufnr, silent = true, noremap = true },
    { "gD", vim.lsp.buf.declaration, { desc = "Buffer declarations" } },
    { "gd", vim.lsp.buf.definition, { desc = "Buffer definitions" } },
    { "K", vim.lsp.buf.hover, { desc = "Show float UI" } },
    { "gi", vim.lsp.buf.implementation, { desc = "Show implementations" } },
    { "<C-k>", vim.lsp.buf.signature_help, { desc = "Signatures" } },
    { "<leader>lwa", vim.lsp.buf.add_workspace_folder, { desc = "Add workspace folder" } },
    { "<leader>lwr", vim.lsp.buf.remove_workspace_folder, { desc = "Remove workspace folder" } },
    {
      "<leader>lwl",
      function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end,
      { desc = "List workspace folders" },
    },
    { "<leader>lD", vim.lsp.buf.type_definition, { desc = "Show type definitions" } },
    { "<leader>lR", vim.lsp.buf.rename, { desc = "Rename buffer" } },
    { "<leader>la", vim.lsp.buf.code_action, { desc = "Show code actions" } },
    { "gr", vim.lsp.buf.references, { desc = "Show buffer references" } }
  )
end

function lsp.setup_server(server, opts)
  opts = opts or {}
  local capabilities = opts.capabilities or lsp.capabilties
  local on_attach = opts.on_attach or lsp.on_attach
  local flags = opts.flags or lsp.flags
  local default_conf = { capabilities = capabilities, on_attach = on_attach, flags = flags }

  default_conf = table.merge(default_conf, opts)

  require("lspconfig")[server].setup(default_conf)
end

function lsp.setup()
  -- Mason.vim, trouble and lsp autoformatting
  require("mason").setup()

  -- Other settings
  vim.diagnostic.config(lsp.diagnostic)

  -- Setup lsp servers
  for _, conf in pairs(Lang.langs) do
    if conf.server then
      lsp.setup_server(conf.server.name, conf.server.config or {})
    end
  end
end

user.plugins.lsp = lsp

req "user.plugins.lsp"
require "core.plugins.lsp.kbd"

lsp.setup()
