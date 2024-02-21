local c = {}

c.compile = {
  buffer = 'gcc {path} && [[ -f ./a.out ]] && ./a.out && rm ./a.out'
}

c.autocmds = {
  insert_at_enter = function ()
    local lines = {
      "#include <stdio.h>",
      "#include <stdarg.h>",
      "",
    }
    Buffer.set(current_buf(), {0, -1}, lines)
  end,
}

c.server = {
  "ccls",
  config = {
    init_options = {
      compilationDatabaseDirectory = "build",
      index = {
        threads = 0,
      },
      clang = {
        excludeArgs = { "-frounding-math" },
      },
    },
  },
}

return c
