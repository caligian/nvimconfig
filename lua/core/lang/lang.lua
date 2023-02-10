-- @class Lang FileType manager
class('Lang')

-- @
Lang.langs = Lang.langs or {}

-- @function Lang._init Constructor function for lang/filetype object
-- @param self self
-- @tparam lang string filetype/language name
-- @return self
function Lang._init(self, lang)
	lang = lang or vim.bo.filetype
	self.init = false
	self.name = lang

	Lang.langs[ft] = self
	return self
end

-- @function Lang.whereis
-- Use whereis to get the binary path and optionally use regex to get the desired one
-- This by default uses the first path in the list
-- @tparam bin string Name of the binary
-- @tparam[opt] regex string Valid lua regex
-- @treturn ?string Path that can be used or false
function Lang.whereis(bin, regex)
	local out = vim.fn.system('whereis ' .. bin .. [[ | cut -d : -f 2- | sed -r "s/(^ *| *$)//mg"]])
	out = V.trim(out)
	out = vim.split(out, ' ')

	if V.isblank(out) then return false end

	if regex then
		for _, value in ipairs(out) do
			if value:match(regex) then return value end
		end
	end
	return out[1]
end

---
-- This function is used to setup everything and can be used multiple times
-- The following should be the setup table
--[[
{
    -- Build, test, compile to be used with :compile
    -- You can use a lua pattern to match against the paths found by using Lang.whereis
    compile = {string, string} or string,
    build = {string, string} or string,
    test = {string, string} or string,
    efm = {
        -- For the aforementioned operations for qflist
        compile = string,
        build = string,
        test = string,
    },

    -- REPL command for this lang
    repl = string,

    -- Debugger to run with REPL
    debug = string,

    -- This will be used by nvim-lspconfig 
    server = {
        -- Name of the server
        name = string,

        -- This should be a table following nvim-lspconfig conventions
        config = table,
    },

    -- Formatters following formatter.nvim conventions
    formatters = { {...}, ... }

    -- Linters to be used besides LSP. This will be used with nvim-lint
    linters = table[string],

    -- Buffer options to set when filetype is set with this lang
    bo = {[opt] = value}, 

    -- Callbacks to run when this filetype is set with this lang
    -- These can also be removed using self:unhook()
    -- @see Lang.unhook
    hooks = {<name> = function}
}
--]]
-- @tparam self Lang self
-- @tparam opts table Contains specific information that can be used by this framework
-- @return self
function Lang.setup(self, opts)
	-- Autocmd group
	local group = 'filetype_hook_for_' .. lang
	local au = Autocmd(group)
	self.autocmd = au

	local function add_hooks(opts)
		local hooks = opts.hooks
		if not hooks then return end
		local lang = self.name

		for name, h in pairs(hooks) do
			au:create('FileType', lang, function()
				if V.isstring(h) then
					vim.cmd(h)
				else
					h(self)
				end
			end, { group = lang, name = name })
		end
	end

	local function require_from_config()
		local lang = self.name
		local opts = V.require('core.lang.ft.' .. lang)
		local uopts = V.require('user.lang.ft.' .. lang)

		if not opts and not uopts then
			return false
		else
			return V.lmerge(uopts or {}, opts or {})
		end
	end

	local function checkpaths(opts)
		if opts.test then
			opts.test = V.ensure_list(opts.test)
			local bin = opts.test[1]
			assert(Lang.whereis(bin, opts.test[2]))
			self.test = bin
		end
		if opts.build then
			opts.build = V.ensure_list(opts.build)
			local bin = opts.build[1]
			assert(Lang.whereis(bin, opts.build[2]))
			self.build = bin
		end
		if opts.compile then
			opts.compile = V.ensure_list(opts.compile)
			local bin = opts.compile[1]
			assert(Lang.whereis(bin, opts.compile[2]))
			self.compile = bin
		end
	end

	local function set_bufopts(opts)
		if not opts.bo then return end

		au:create('FileType', self.name, function()
			local bufnr = vim.fn.bufnr()
			for key, value in pairs(opts.bo) do
				vim.api.nvim_buf_set_option(bufnr, key, value)
			end
		end)

		self.bo = opts.bo
	end

	local loaded = require_from_config() or opts
	set_bufopts(loaded)
	add_hooks(loaded)
	checkpaths(loaded)

	self.init = true

	return self
end

function Lang.unhook(self, name)
	if not self.autocmd then return false end
	self.autocmd:remove(name)
end

function Lang.setbufopts(self, opts) self:setup({ bo = opts }) end
