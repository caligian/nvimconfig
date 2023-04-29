-- place this in one of your configuration file(s)
local hop = require "hop"
local directions = require("hop.hint").HintDirection
hop.setup()

K.bind({ mode = "nvx" }, {
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
})

K.bind({mode='nvx'}, {
  "s",
  function()
    hop.hint_char2 {direction = directions.AFTER_CURSOR}
  end,
}, {
  "<A-s>",
  function()
    hop.hint_char2 {direction = directions.BEFORE_CURSOR}
  end,
})
