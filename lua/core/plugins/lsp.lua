local lsp = plugin.lsp
lsp.capabilties = require("cmp_nvim_lsp").default_capabilities()

-- Turn off annoying virtual text
lsp.diagnostic = {
  virtual_text = false,
  underline = false,
  update_in_insert = false,
}

lsp.kbd = {
  noremap = true,
  {
    "<leader>li",
    partial(vim.diagnostic.open_float, { scope = "l", focus = false }),
    { desc = "LSP diagnostic float", name = "lsp_diagnostic_float" },
  },
  {
    "[d",
    vim.diagnostic.goto_prev,
    { desc = "LSP go to previous diagnostic", name = "lsp_prev_diagnostic" },
  },
  {
    "]d",
    vim.diagnostic.goto_next,
    { desc = "LSP go to next diagnostic", name = "lsp_next_diagnostic" },
  },
  {
    "<leader>lq",
    vim.diagnostic.setloclist,
    { desc = "LSP set loclist", name = "lsp_set_loclist" },
  },
}

lsp.mappings = {
  silent = true,
  noremap = true,
  { "gD", vim.lsp.buf.declaration, { desc = "Buffer declarations" } },
  { "gd", vim.lsp.buf.definition, { desc = "Buffer definitions" } },
  { "K", vim.lsp.buf.hover, { desc = "Show float UI" } },
  { "gi", vim.lsp.buf.implementation, { desc = "Show implementations" } },
  { "<C-k>", vim.lsp.buf.signature_help, { desc = "Signatures" } },
  {
    "<leader>lwa",
    vim.lsp.buf.add_workspace_folder,
    { desc = "Add workspace folder" },
  },
  {
    "<leader>lwr",
    vim.lsp.buf.remove_workspace_folder,
    { desc = "Remove workspace folder" },
  },
  {
    "<leader>lwl",
    function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
    { desc = "List workspace folders" },
  },
  {
    "<leader>lD",
    vim.lsp.buf.type_definition,
    { desc = "Show type definitions" },
  },
  { "<leader>lR", vim.lsp.buf.rename, { desc = "Rename buffer" } },
  { "<leader>la", vim.lsp.buf.code_action, { desc = "Show code actions" } },
  { "gr", vim.lsp.buf.references, { desc = "Show buffer references" } },
}

lsp.methods = {
  on_attach = function(bufnr)
    if not bufnr then return end
    buffer.setopt(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

    if not dict.contains(Filetype.ft, vim.bo.filetype, "formatters") then
      require("lsp-format").on_attach(client)
    end

    local mappings = utils.copy(self.mappings)
    mappings.bufnr = bufnr

    K.bind(mappings)
  end,

  setup_server = function(server, opts)
    opts = opts or {}
    local capabilities = opts.capabilities or lsp.capabilties
    local on_attach = opts.on_attach or lsp.methods.on_attach
    local flags = opts.flags or lsp.flags
    local default_conf =
      { capabilities = capabilities, on_attach = on_attach, flags = flags }

    default_conf = dict.merge(default_conf, opts)

    require("lspconfig")[server].setup(default_conf)
  end,
}

function lsp:on_attach()
  require("mason").setup()
  require("fidget").setup {}

  -- Other settings
  vim.diagnostic.config(lsp.diagnostic)

  -- Setup lsp servers
  for _, conf in pairs(user.filetype) do
    if conf.server then
      if is_string(conf.server) then conf.server = { name = conf.server } end
      lsp.methods.setup_server(conf.server.name, conf.server.config or {})
    end
  end
end
