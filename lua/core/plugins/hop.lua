-- place this in one of your configuration file(s)
local hop = require "hop"
local directions = require("hop.hint").HintDirection
hop.setup()

K.bind({ mode = "nvx", noremap = false, remap = true }, {
  "g/",
  function()
    hop.hint_patterns {}
  end,
  "Hop to pattern",
}, {
  "gl",
  function()
    hop.hint_lines_skip_whitespace {}
  end,
}, {
  "gJ",
  function()
    hop.hint_lines_skip_whitespace { direction = directions.AFTER_CURSOR }
  end,
}, {
  "gK",
  utils.log_pcall_wrap(function()
    hop.hint_lines_skip_whitespace { direction = directions.BEFORE_CURSOR }
  end),
}, {
  "s",
  function()
    hop.hint_char2 {}
  end,
})

vim.keymap.set("", "f", function()
  hop.hint_char1 {
    direction = directions.AFTER_CURSOR,
    current_line_only = true,
  }
end, { remap = true })

vim.keymap.set("", "F", function()
  hop.hint_char1 {
    direction = directions.BEFORE_CURSOR,
    current_line_only = true,
  }
end, { remap = true })

vim.keymap.set("", "t", function()
  hop.hint_char1 {
    direction = directions.AFTER_CURSOR,
    current_line_only = true,
    hint_offset = -1,
  }
end, { remap = true })

vim.keymap.set("", "T", function()
  hop.hint_char1 {
    direction = directions.BEFORE_CURSOR,
    current_line_only = true,
    hint_offset = 1,
  }
end, { remap = true })
