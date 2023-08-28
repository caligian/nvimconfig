local surround = Plugin.get "surround"

function surround:setup()
    require("nvim-surround").setup(self.config or {})
end

return surround
