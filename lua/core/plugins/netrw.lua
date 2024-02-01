local netrw = {}

netrw.config = {
  icons = {
    symlink = "S",
    directory = "D",
    file = "F",
  },
  use_devicons = true,
  mappings = {},
}

function netrw:setup()
  require("netrw").setup(self.config)
end

return netrw
