user.builtin.lsp = {
    flags = {
        -- This is the default in Nvim 0.7+
       debounce_text_changes = 150,
    },
    capabilities = require('cmp_nvim_lsp').default_capabilities(),
    sumneko_lua = {
        settings = {
            Lua = {diagnostics={globals={'vim'}}},
        }
    },
}
local cmp = require('cmp')
local lsp = user.builtin.lsp
local config_lsp = user.config.lsp or {}
local config = vim.tbl_extend("force", lsp, config_lsp)
local cmp_ultisnips_mappings = require("cmp_nvim_ultisnips.mappings")

-- Setup nvim-cmp
cmp.setup {
    mapping = {
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
local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<leader>ld', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<leader>lq', vim.diagnostic.setloclist, opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
function lsp.on_attach(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<leader>lwa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<leader>lwr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<leader>lwl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<leader>lD', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<leader>lR', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<leader>lf', function() vim.lsp.buf.format { async = true } end, bufopts)
end

function lsp.setup_server(server, opts)
    opts = opts or {}
    opts.capabilities = opts.capabilities or config.capabilities
    opts.on_attach = opts.on_attach or config.on_attach
    opts.flags = opts.flags or config.flags

    local default_conf = {
        capabilities=opts.capabilities,
        on_attach=opts.on_attach,
        flags=opts.flags
    }

    if lsp[server] then
        default_conf = vim.tbl_extend('force', default_conf, lsp[server])
    end

    require('lspconfig')[server].setup(default_conf)
end

lsp.setup_server('pyright')
lsp.setup_server('solargraph')
lsp.setup_server('sumneko_lua')
