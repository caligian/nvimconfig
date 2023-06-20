local metals_config = require("metals").bare_config()

metals_config.settings = {
  showImplicitArguments = true,
  excludedPackages = {
    "akka.actor.typed.javadsl",
    "com.github.swagger.akka.javadsl",
  },
}

metals_config.capabilities = require("cmp_nvim_lsp").default_capabilities()

plugin.scala_ls = {
  config = metals_config,
  on_attach = function(self)
    require('metals').initialize_or_attach(self.config)
  end,
  autocmds = {
    load_config = {
      'FileType',
      {
        group = 'ScalaMetal',
        pattern = {'scala', 'sbt', 'java'},
        callback = function ()
          plugin.scala_ls:on_attach()
        end
      }
    }
  }
}
