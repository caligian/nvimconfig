local plug = {}

plug.mappings = {
  hint_patterns = {
    "nvx",
    "g/",
    function()
      local hop = require "hop"
      local directions = require("hop.hint").HintDirection
      hop.hint_patterns {}
    end,
    "jmp to pattern",
  },
  skip_whitespace = {
    "nvx",
    "gl",
    function()
      local hop = require "hop"
      local directions = require("hop.hint").HintDirection

      hop.hint_lines_skip_whitespace {}
    end,
    "hint lines",
  },
  after_cursor = {
    "nvx",
    "gJ",
    function()
      local hop = require "hop"
      local directions = require("hop.hint").HintDirection

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
      local hop = require "hop"
      local directions = require("hop.hint").HintDirection

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
      local hop = require "hop"
      local directions = require("hop.hint").HintDirection

      hop.hint_char2 { direction = directions.AFTER_CURSOR }
    end,
    "hint after 2 chars",
  },
  hint_char2_before_cursor = {
    "nvx",
    "<A-s>",
    function()
      local hop = require "hop"
      local directions = require("hop.hint").HintDirection
      hop.hint_char2 { direction = directions.BEFORE_CURSOR }
    end,
    "hint before 2 chars",
  },
}

function plug:setup()
  local hop = require "hop"
  local directions = require("hop.hint").HintDirection
  hop.setup()
end

return plug
