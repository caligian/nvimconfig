user.lang.langs = user.lang.langs or {}
local lang = user.lang

local src = path.join(vim.fn.stdpath("config"), "lua", "core", "lang", "ft")
for _, d in ipairs(dir.getdirectories(src)) do
	d = path.basename(d)
	local config = V.require("core.lang.ft." .. d)
	if config then
		user.lang.langs[d] = config
	end
end

for ft, config in pairs(user.lang.langs) do
	if config.bo then
		Autocmd("FileType", {
			pattern = ft,
			callback = function()
				for key, value in pairs(config.bo) do
					vim.bo[key] = value
				end
			end,
		})
	end
end
