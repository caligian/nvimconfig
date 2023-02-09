return require('lazy').setup({
	{ 'nvim-lua/plenary.nvim' },

	{ 'nvim-tree/nvim-web-devicons', event = 'WinEnter', config = function() V.require('nvim-web-devicons').setup({}) end },

	{
		'nvim-tree/nvim-tree.lua',
		event = 'WinEnter',
		config = function()
			user.plugins['nvim-tree.lua'] = {}
			V.require('user.nvim-tree_lua')

			require('nvim-tree').setup(user.plugins['nvim-tree.lua'])

			Keybinding({ noremap = true, leader = true }):bind({
				{ '|', ':NvimTreeToggle<CR>', 'Focus tree explorer' },
				{ '\\', ':NvimTreeFocus<CR>', 'Toggle tree explorer' },
			})
		end,
	},

	{
		'beauwilliams/statusline.lua',
		config = function()
			local statusline = require('statusline')
			statusline.tabline = true
			statusline.lsp_diagnostics = true
			vim.o.laststatus = 3
		end,
	},

	{ 'tpope/vim-surround', event = 'InsertEnter' },

	{ 'justinmk/vim-sneak', event = 'InsertEnter' },

	{ 'Raimondi/delimitMate', event = 'InsertEnter' },

	{ 'psliwka/vim-smoothie', event = 'WinEnter' },

	{
		'mfussenegger/nvim-lint',
		event = 'BufReadPost',
		config = function() V.require('core.plugins.nvim-lint') end,
	},

	{ 'jasonccox/vim-wayland-clipboard', keys = '"' },

	{ 'dstein64/vim-startuptime', cmd = 'StartupTime' },

	{ 'tpope/vim-commentary', keys = 'g' },

	{ 'lervag/vimtex', ft = 'tex' },

	{ 'jaawerth/fennel.vim', ft = 'fennel' },

	{
		'Olical/conjure',
		ft = {
			'clojure',
			'fennel',
			'common-lisp',
			'guile',
			'hy',
			'janet',
			'julia',
			'lua',
			'python',
			'racket',
			'rust',
			'scheme',
		},
	},

	{
		'nvim-treesitter/nvim-treesitter',
		event = 'InsertEnter',
		dependencies = { 'RRethy/nvim-treesitter-textsubjects', 'nvim-treesitter/nvim-treesitter-textobjects' },
		config = function() require('core.plugins.nvim-treesitter') end,
	},

	{
		'hrsh7th/nvim-cmp',
		event = 'InsertEnter',
		dependencies = {
			{ 'honza/vim-snippets' },
			{ 'SirVer/ultisnips' },
			{ 'quangnguyen30192/cmp-nvim-ultisnips' },
			{ 'tamago324/cmp-zsh' },
			{ 'hrsh7th/cmp-buffer' },
			{ 'f3fora/cmp-spell' },
			{ 'hrsh7th/cmp-nvim-lsp' },
			{ 'ray-x/cmp-treesitter' },
			{ 'hrsh7th/cmp-nvim-lua' },
			{ 'hrsh7th/cmp-path' },
			{ 'hrsh7th/cmp-nvim-lsp-signature-help' },
			{ 'hrsh7th/cmp-nvim-lsp-document-symbol' },
		},
	},

	{
		'tpope/vim-fugitive',
		keys = '<leader>g',
		config = function()
			Keybinding({ noremap = true, leader = true, mode = 'n' }):bind({
				{ 'gg', ':Git<CR>' },
				{ 'gs', ':Git stage <CR>' },
				{ 'gc', ':Git commit <CR>' },
			})
		end,
	},

	{
		'preservim/tagbar',
		keys = '<C-t>',
		config = function() Keybinding.noremap('n', '<C-t>', ':TagbarToggle<CR>', { desc = 'Toggle tagbar' }) end,
	},

	{
		'flazz/vim-colorschemes',
		config = function() vim.cmd('colorscheme ' .. user.colorscheme) end,
	},

	{
		'folke/which-key.nvim',
		event = 'WinEnter',
		config = function() V.require('core.plugins.which-key_nvim') end,
	},

	{
		'iamcco/markdown-preview.nvim',
		build = 'cd app && yarn install',
		ft = 'markdown',
	},

	{
		'mhartington/formatter.nvim',
		event = 'BufReadPost',
		config = function() V.require('core.plugins.formatter_nvim') end,
	},

	{
		'neovim/nvim-lspconfig',
		ft = V.filter(function(k)
			if V.haskey(user.lang.langs, k, 'server') then return k end
		end, V.keys(user.lang.langs)),
		dependencies = {
			{ 'lukas-reineke/lsp-format.nvim' },
			{ 'SirVer/ultisnips' },
			{ 'williamboman/mason.nvim' },
			{ 'hrsh7th/nvim-cmp' },
		},
		config = function() V.require('core.plugins.nvim-lspconfig') end,
	},

	{
		'nvim-telescope/telescope.nvim',
		dependencies = {
			{ 'hrsh7th/nvim-cmp' },
			{ 'nvim-telescope/telescope-file-browser.nvim' },
			{ 'nvim-telescope/telescope-project.nvim' },
			{ 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
		},
		config = function() V.require('core.plugins.telescope_nvim') end,
	},

	{
		'moll/vim-bbye',
		event = 'BufReadPre',
		config = function()
			Keybinding({ noremap = true, leader = true }):bind({
				{ 'bq', '<cmd>Bdelete<CR>', { desc = 'Delete buffer' } },
				{ 'bQ', '<cmd>Bwipeout<CR>', { desc = 'Wipeout buffer' } },
			})
		end,
	},
}, { lazy = true })
