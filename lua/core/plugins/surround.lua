local surround = plugin.get "surround"

function surround:setup()
    require("nvim-surround").setup(self.config or {})
end
