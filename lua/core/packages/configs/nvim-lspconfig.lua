update(user.builtin, {'lsp'}, {
    flags = {
        debounce_text_changes = 150,
    },
    capabilities = require('cmp_nvim_lsp').default_capabilities(),
    servers = {
        sumneko_lua = {
            settings = {
                Lua = {diagnostics={globals={'vim', 'unpack', 'loadfile', 'user'}}},
            }
        },
        pyright = true,
        solargraph = true,
        texlab = true,
    },
})

local cmp = require('cmp')
local lsp = user.builtin.lsp
user.config.lsp = user.config.lsp or lsp
local cmp_ultisnips_mappings = require("cmp_nvim_ultisnips.mappings")

-- Setup nvim-cmp
cmp.setup {
    mapping = {
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-j>'] = cmp.mapping.select_next_item(),
        ['<C-k>'] = cmp.mapping.select_prev_item(),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ["<Tab>"] = cmp.mapping(function(fallback)
            cmp_ultisnips_mappings.expand_or_jump_forwards(fallback)
        end,
        { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
            cmp_ultisnips_mappings.jump_backwards(fallback)
        end,
        { "i", "s" }),
    },
    snippet = {
        expand = function(args)
            vim.fn["UltiSnips#Anon"](args.body)
        end
    },
    sources = {
        { name = 'path' },
        { name = 'ultisnips' },
        { name = 'buffer' },
        { name = 'treesitter' },
        { name = 'nvim_lsp' },
        { name = 'nvim_lua' },
        { name = 'zsh' },
        { name = 'nvim_lsp_signature_help' },
        {
            name = 'spell',
            option = {
                keep_all_entries = false,
                enable_in_context = function()
                    return true
                end,
            },
        },
    },
}

-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
user.builtin.kbd.noremap_with_options({silent=true},
{'n', '<leader>ld', vim.diagnostic.open_float, {desc='LSP diagnostic float'}},
{'n', '[d', vim.diagnostic.goto_prev, {desc='LSP go to previous diagnostic'}},
{'n', ']d', vim.diagnostic.goto_next, {desc='LSP go to next diagnostic'}},
{'n', '<leader>lq', vim.diagnostic.setloclist, {desc='LSP set loclist'}})

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
function lsp.on_attach(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  user.builtin.kbd.noremap_with_options({buffer=bufnr, silent=true},
  {'n', 'gD', vim.lsp.buf.declaration, {desc='Buffer declarations'}},
  {'n', 'gd', vim.lsp.buf.definition, {desc='Buffer definitions'}},
  {'n', 'K', vim.lsp.buf.hover, {desc='Show float UI'}},
  {'n', 'gi', vim.lsp.buf.implementation, {desc='Show implementations'}},
  {'n', '<C-k>', vim.lsp.buf.signature_help, {desc='Signatures'}},
  {'n', '<leader>lwa', vim.lsp.buf.add_workspace_folder, {desc='Add workspace folder'}},
  {'n', '<leader>lwr', vim.lsp.buf.remove_workspace_folder, {desc='Remove workspace folder'}},
  {'n', '<leader>lwl', function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, {desc='List workspace folders'}},
  {'n', '<leader>lD', vim.lsp.buf.type_definition, {desc='Show type definitions'}},
  {'n', '<leader>lR', vim.lsp.buf.rename, {desc='Rename buffer'}},
  {'n', '<leader>la', vim.lsp.buf.code_action, {desc='Show code actions'}},
  {'n', 'gr', vim.lsp.buf.references, {desc='Show buffer references'}},
  {'n', '<leader>lf', function() vim.lsp.buf.format { async = true } end, {desc='Format buffer'}})
end

function lsp.setup_server(server, opts)
    opts = opts or {}
    local user_config = user.config.lsp or {}
    user_config = extend('keep', user.config.lsp, lsp)
    local capabilities = opts.capabilities or user_config.capabilties
    local on_attach = opts.on_attach or user_config.on_attach
    local flags = opts.flags or user_config.flags
    local default_conf = { capabilities = capabilities, on_attach = on_attach, flags = flags }
    local server_conf = get(user_config, {'servers', server}) or lsp.servers[server]
    server_conf = server_conf == true and default_conf or server_conf
    default_conf = extend('keep', server_conf, default_conf)

    require('lspconfig')[server].setup(default_conf)
end

local servers = extend('keep', user.config.lsp.servers or {}, lsp.servers)
for server, conf in pairs(servers) do
    lsp.setup_server(server, conf == true and {})
end
