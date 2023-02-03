local defaults = builtin.require 'core.pkg.configs.nvim-lspconfig.defaults'
local cmp = builtin.require('cmp')
local cmp_ultisnips_mappings = builtin.require("cmp_nvim_ultisnips.mappings")
local lsp = user.lsp
lsp.capabilties = builtin.require('cmp_nvim_lsp').default_capabilities()

Package.defaults['trouble.nvim'] = {
    icons = false,
    fold_open = "v",
    fold_closed = ">",
    indent_lines = false,
    use_diagnostic_signs = false,
    signs = {
        error = "Error",
        warning = "Warn",
        hint = "Hint",
        information = "Info",
        other = "Misc"
    },
}

Package.defaults['ultisnips'] = {
    expand_trigger = '<C-o>',
    jump_forward_trigger = '<C-j>',
    jump_backward_trigger = '<C-k>',
    edit_split = 'vertical',
}

Package.defaults['nvim-lspconfig'] = defaults

-- Turn off annoying virtual text
lsp.diagnostic = {
    virtual_text = false
}

Package.defaults['nvim-cmp'] = {
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

-- Load user overrides
builtin.require 'user.pkg.configs.nvim-lspconfig'

function lsp.on_attach(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Setup buffer formatting
    builtin.require('lsp-format').on_attach(client)

    -- Setup keybindings
    Keybinding({ buffer = bufnr, silent = true }):bind {
        { 'gD', vim.lsp.buf.declaration, { desc = 'Buffer declarations' } },
        { 'gd', vim.lsp.buf.definition, { desc = 'Buffer definitions' } },
        { 'K', vim.lsp.buf.hover, { desc = 'Show float UI' } },
        { 'gi', vim.lsp.buf.implementation, { desc = 'Show implementations' } },
        { '<C-k>', vim.lsp.buf.signature_help, { desc = 'Signatures' } },
        { '<leader>lwa', vim.lsp.buf.add_workspace_folder, { desc = 'Add workspace folder' } },
        { '<leader>lwr', vim.lsp.buf.remove_workspace_folder, { desc = 'Remove workspace folder' } },
        { '<leader>lwl', function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
            { desc = 'List workspace folders' } },
        { '<leader>lD', vim.lsp.buf.type_definition, { desc = 'Show type definitions' } },
        { '<leader>lR', vim.lsp.buf.rename, { desc = 'Rename buffer' } },
        { '<leader>la', vim.lsp.buf.code_action, { desc = 'Show code actions' } },
        { 'gr', vim.lsp.buf.references, { desc = 'Show buffer references' } },
        { '<leader>lf', function() vim.lsp.buf.format { async = true } end, { desc = 'Format buffer' } }
    }
end

function lsp.setup_server(server, opts)
    opts = opts or {}
    local capabilities = opts.capabilities or lsp.capabilties
    local on_attach = opts.on_attach or lsp.on_attach
    local flags = opts.flags or lsp.flags
    local default_conf = { capabilities = capabilities, on_attach = on_attach, flags = flags }

    default_conf = builtin.merge(default_conf, opts)

    builtin.require('lspconfig')[server].setup(default_conf)
end

function lsp.setup()
    local snippet = Package.defaults['ultisnips']
    local cmpconf = Package.defaults['nvim-cmp']
    local trouble = Package.defaults['trouble.nvim']

    -- Mason.vim, trouble and lsp autoformatting
    builtin.require('mason').setup()
    builtin.require('trouble').setup(trouble)
    builtin.require('lsp-format').setup()

    -- Ultisnips
    vim.g.UltiSnipsExpandTrigger = snippet.expand_trigger
    vim.g.UltiSnipsJumpForwardTrigger = snippet.jump_forward_trigger
    vim.g.UltiSnipsJumpBackwardTrigger = snippet.jump_backward_trigger
    vim.g.UltiSnipsEditSplit = snippet.edit_split

    -- Other settings
    vim.diagnostic.config(lsp.diagnostic)

    -- nvim-cmp
    cmp.setup(cmpconf)

    -- Setup lsp servers
    for ft, conf in pairs(user.lang.langs) do
        if conf.server then
            lsp.setup_server(conf.server.name, conf.server.config or {})
        end
    end
end

-- Trouble mappings
Keybinding({ silent = true, noremap = true, leader = true }):bind {
    { "ltt", "<cmd>TroubleToggle<cr>", { desc = 'Toggle trouble' } },
    { "ltw", "<cmd>TroubleToggle workspace_diagnostics<cr>", { desc = 'Workspace diagnostics' } },
    { "ltd", "<cmd>TroubleToggle document_diagnostics<cr>", { desc = 'Document diagnostics' } },
    { "ltl", "<cmd>TroubleToggle loclist<cr>", { desc = 'Show loclist' } },
    { "ltq", "<cmd>TroubleToggle quickfix<cr>", { desc = 'Show qflist' } },
}

-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
Keybinding({ silent = true }):bind {
    { '<leader>li', builtin.partial(vim.diagnostic.open_float, { scope = 'l', focus = false }),
        { desc = 'LSP diagnostic float' } },
    { '[d', vim.diagnostic.goto_prev, { desc = 'LSP go to previous diagnostic' } },
    { ']d', vim.diagnostic.goto_next, { desc = 'LSP go to next diagnostic' } },
    { '<leader>lq', vim.diagnostic.setloclist, { desc = 'LSP set loclist' } }
}

-- Setup LSP
lsp.setup()
