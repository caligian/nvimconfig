local netrw = {}

netrw.config = {
  icons = {
    symlink = "", -- Symlink icon (directory and file)
    directory = "", -- Directory icon
    file = "",
  },
  use_devicons = true,
  mappings = {
    B = function (opts)
      local path = Path.join(opts.dir, opts.node)
      Bookmark.add_and_save(path)
    end
  },
}

function netrw:setup()
  require("netrw").setup(self.config)
end

netrw:setup()

return netrw
