local plug = {}
local hop = require "hop"
local directions = require("hop.hint").HintDirection

plug.mappings = {
  hint_patterns = {
    "nvx",
    "g/",
    function()
      hop.hint_patterns {}
    end,
    "jmp to pattern",
  },
  skip_whitespace = {
    "nvx",
    "gl",
    function()
      hop.hint_lines_skip_whitespace {}
    end,
    "hint lines",
  },
  after_cursor = {
    "nvx",
    "gJ",
    function()
      hop.hint_lines_skip_whitespace {
        direction = directions.AFTER_CURSOR,
      }
    end,
    "hint lines after cursor",
  },
  before_cursor = {
    "nvx",
    "gK",
    function()
      hop.hint_lines_skip_whitespace {
        direction = directions.BEFORE_CURSOR,
      }
    end,
    "hint lines before cursor",
  },
  hint_char2_after_cursor = {
    "nvx",
    "s",
    function()
      hop.hint_char2 { direction = directions.AFTER_CURSOR }
    end,
    "hint after 2 chars",
  },
  hint_char2_before_cursor = {
    "nvx",
    "S",
    function()
      hop.hint_char2 { direction = directions.BEFORE_CURSOR }
    end,
    'hint before 2 chars'
  },
}

function plug:setup()
  hop.setup()
end

return plug
