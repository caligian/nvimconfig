local plug = plugin.get "hop"
local hop = require "hop"
local directions = require("hop.hint").HintDirection

plug.mappings = {
    opts = { mode = "nvx" },
    hint_patterns = {
        "g/",
        function()
            hop.hint_patterns {}
        end,
        "Hop to pattern",
    },
    skip_whitespace = {
        "gl",
        function()
            hop.hint_lines_skip_whitespace {}
        end,
    },
    after_cursor = {
        "gJ",
        function()
            hop.hint_lines_skip_whitespace { direction = directions.AFTER_CURSOR }
        end,
    },
    before_cursor = {
        "gK",
        function()
            hop.hint_lines_skip_whitespace {
                direction = directions.BEFORE_CURSOR,
            }
        end,
    },
    hint_char2_after_cursor = {
        "s",
        function()
            hop.hint_char2 { direction = directions.AFTER_CURSOR }
        end,
    },
    hint_char2_before_cursor = {
        "<A-s>",
        function()
            hop.hint_char2 { direction = directions.BEFORE_CURSOR }
        end,
    },
}

function plug:setup()
    hop.setup()
end

return plug
