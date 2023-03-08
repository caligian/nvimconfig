return {
  neosolarized = function(config)
    config = config or {}
    local defaults = {
      comment_italics = true,
      background_set = true,
    }
    lmerge(config, defaults)
    require("neosolarized").setup(config)
  end,
}
