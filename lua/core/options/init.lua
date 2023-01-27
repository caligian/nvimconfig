local data_dir = vim.fn.stdpath('data')
local options = {}
user.options = {
	options = {
		o = {
			foldenable = false,
			timeoutlen = 350,
			completeopt = "menu,menuone,noselect",
			mouse = "a",
			history = 1000,
			ruler = true,
			autochdir = true,
			showcmd = true,
			wildmode = "longest,list,full",
			wildmenu = true,
			termguicolors = true,
			laststatus = 2,
			mousefocus = true,
			shell = "/usr/bin/zsh",
			backspace = "indent,eol,start",
			number = true,
			tabstop = 4,
			shiftwidth = 4,
			expandtab = true,
			foldmethod = "indent",
			inccommand = 'split',
			background = 'dark',
			guifont = 'Hack Nerd Font:h13',
			laststatus = 2,
			backupdir = data_dir .. '/temp/backups',
			directory = data_dir .. '/temp/tmp',
			undodir = data_dir .. '/temp/undo',

		},
		g = {
			mapleader = " ",
			maplocalleader = ",",
		},
	},
	
}

require_user 'user.options'
options = user.options

function options.setup()
	for t, opts in pairs(options.options) do
		for k, v in pairs(opts) do
			vim[t][k] = v
		end
	end
end

options.setup()
