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
  { "gD",    vim.lsp.buf.declaration,    { desc = "Buffer declarations" } },
  { "gd",    vim.lsp.buf.definition,     { desc = "Buffer definitions" } },
  { "K",     vim.lsp.buf.hover,          { desc = "Show float UI" } },
  { "gi",    vim.lsp.buf.implementation, { desc = "Show implementations" } },
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
  { "<leader>lR", vim.lsp.buf.rename,      { desc = "Rename buffer" } },
  { "leaderla",   vim.lsp.buf.code_action, { desc = "Show code actions" } },
  {
    "gr",
    vim.lsp.buf.references,
    { desc = "Show buffer references" },
  },
}

lsp.methods = {
  fix_omnisharp = function(client, bufnr)
    client.server_capabilities.semanticTokensProvider = {
      full = vim.empty_dict(),
      legend = {
        tokenModifiers = { "static_symbol" },
        tokenTypes = {
          "comment",
          "excluded_code",
          "identifier",
          "keyword",
          "keyword_control",
          "number",
          "operator",
          "operator_overloaded",
          "preprocessor_keyword",
          "string",
          "whitespace",
          "text",
          "static_symbol",
          "preprocessor_text",
          "punctuation",
          "string_verbatim",
          "string_escape_character",
          "class_name",
          "delegate_name",
          "enum_name",
          "interface_name",
          "module_name",
          "struct_name",
          "type_parameter_name",
          "field_name",
          "enum_member_name",
          "constant_name",
          "local_name",
          "parameter_name",
          "method_name",
          "extension_method_name",
          "property_name",
          "event_name",
          "namespace_name",
          "label_name",
          "xml_doc_comment_attribute_name",
          "xml_doc_comment_attribute_quotes",
          "xml_doc_comment_attribute_value",
          "xml_doc_comment_cdata_section",
          "xml_doc_comment_comment",
          "xml_doc_comment_delimiter",
          "xml_doc_comment_entity_reference",
          "xml_doc_comment_name",
          "xml_doc_comment_processing_instruction",
          "xml_doc_comment_text",
          "xml_literal_attribute_name",
          "xml_literal_attribute_quotes",
          "xml_literal_attribute_value",
          "xml_literal_cdata_section",
          "xml_literal_comment",
          "xml_literal_delimiter",
          "xml_literal_embedded_expression",
          "xml_literal_entity_reference",
          "xml_literal_name",
          "xml_literal_processing_instruction",
          "xml_literal_text",
          "regex_comment",
          "regex_character_class",
          "regex_anchor",
          "regex_quantifier",
          "regex_grouping",
          "regex_alternation",
          "regex_text",
          "regex_self_escaped_character",
          "regex_other_escape",
        },
      },
      range = true,
    }
  end,

  on_attach = function(client, bufnr)
    if client.name == "omnisharp" then
      lsp.methods.fix_omnisharp(client, bufnr)
    else
      buffer.setoption(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
      if
          not Filetype.get(
            buffer.call(bufnr, function() return vim.bo.filetype end),
            "formatter"
          )
      then
        require("lsp-format").on_attach(client)
      end

      local mappings = utils.copy(self.mappings)
      mappings.bufnr = bufnr
      K.bind(mappings)
    end
  end,

  setup_server = function(server, opts)
    if not server then return end

    opts = opts or {}
    local capabilities = opts.capabilities or lsp.capabilties
    local on_attach = opts.on_attach or lsp.methods.on_attach
    local flags = opts.flags or lsp.flags
    local default_conf =
    { capabilities = capabilities, on_attach = on_attach, flags = flags }

    default_conf = dict.merge(default_conf, opts)
    if default_conf.cmd then
      default_conf.cmd = array.toarray(default_conf.cmd)
    end

    require("lspconfig")[server].setup(default_conf)
  end,
}

function lsp:on_attach()
  require("fidget").setup {}

  -- Other settings
  vim.diagnostic.config(lsp.diagnostic)

  dict.each(Filetype.get "server", function(lang, conf)
    local name

    if is_a.string(conf) then
      name = conf
      conf = {}
    else
      name = conf[1]
      conf = conf or {}
    end

    config = conf.config

    lsp.methods.setup_server(name, config)
  end)
end
