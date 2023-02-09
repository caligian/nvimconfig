-- We are only using this if LSP formatting is not available
-- Therefore this will not be setup for all langs

local util = require('formatter.util')
local formatters = {}

for lang, conf in pairs(user.lang.langs) do
	if conf.formatters then
		for idx, formatter in ipairs(conf.formatters) do
			if V.isstring(formatter) then
				local out = V.require(sprintf('formatter.filetypes.%s', lang))
				if out then
					conf.formatters[idx] = out
				else
					conf.formatters[idx] = nil
				end
			elseif V.istable(formatter) then
				conf.formatters[idx] = function()
					formatter.args = formatter.args or {}
					local idx = V.index(formatter.args, '{}')
					if idx then formatter.args[idx] = vim.fn.expand('%:p') end
					formatter.no_append = true
					formatter.cwd = vim.fn.getcwd()
					formatter.ignore_exitcode = false

					return formatter
				end
			end
		end
		formatters[lang] = conf.formatters
	end
end

-- Setup formatter
user.plugins['formatter.nvim'] = { filetype = formatters }

-- Finalize setup
require('formatter').setup(user.plugins['formatter.nvim'])

-- Setup autocmd for autoformatting
local a = Autocmd('Formatter')
for lang, _ in pairs(formatters) do
	Keybinding.noremap('n', '<leader>bf', 'FormatWrite<CR>', { event = 'FileType', pattern = lang, desc = 'Formatter buffer', silent = true })

	a:create('BufWritePost', '*', 'silent! FormatWrite')
end
