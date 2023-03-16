-- place this in one of your configuration file(s)
local hop = require "hop"
local directions = require("hop.hint").HintDirection

K.bind(
  { mode = "nvx", noremap = false },
  { "g/", function() hop.hint_patterns {} end, "Hop to pattern" },
  { "gl", function() hop.hint_lines_skip_whitespace {} end },
  {
    "gJ",
    function()
      hop.hint_lines_skip_whitespace { direction = directions.AFTER_CURSOR }
    end,
  },
  {
    "gK",
    function()
      hop.hint_lines_skip_whitespace { direction = directions.BEFORE_CURSOR }
    end,
  },
  { "s", function() hop.hint_char2 {} end },
  { "S", function() hop.hint_words {} end }
)

hop.setup()
