local shlex = {}

---
-- @tparam string cmd
-- @treturn array[string] quoted contents
local function get_quoted(cmd)
    local first_quote = string.find(cmd, "'") or string.find(cmd, '"')

    if not first_quote then
        return split(cmd, " ")
    end

    local quote = string.sub(cmd, first_quote, first_quote)
    local cache = { true }
    local res = { { false, substr(cmd, 1, first_quote - 1) } }
    local lim = #cmd
    local i = first_quote + 1
    local other_quote = quote == "'" and '"' or "'"

    while i <= lim do
        local c = cmd:sub(i, i)
        local prev = cmd:sub(i - 1, i - 1)
        local is_quote = c == quote
        local backslash = prev and prev == "\\"
        local escaped = backslash and is_quote

        if escaped or not is_quote then
            append(cache, c)
        elseif is_quote and not escaped then
            append(res, { true, join(array.slice(cache, 2), "") })

            cache = { true }

            local new_i = string.find(cmd, quote, i + 1) or string.find(cmd, other_quote, i + 1)

            if not new_i then
                break
            else
                local remaining = string.sub(cmd, i + 1, new_i - 1)
                append(res, { false, remaining })
                i = new_i
                quote = substr(cmd, new_i, new_i)
            end
        end

        i = i + 1
    end

    if i <= lim then
        append(res, { false, substr(cmd, i + 1, lim) })
    end

    return res
end

--- parse a command string split by whitespace and quotes
-- @tparam cmd string command to parse
-- @treturn array[string]
function shlex.parse(cmd)
    local parsed = get_quoted(cmd)
    local res = {}

    array.ieach(parsed, function(i, status)
        local is_quoted, s = unpack(status)
        local prev_status = parsed[i - 1]
        prev_status = prev_status and prev_status[2]
        local prev_status_len = prev_status and #prev_status
        local last_char = prev_status and substr(prev_status, prev_status_len, prev_status_len)
        local ends_with_dollar = last_char == "$" and is_quoted

        if ends_with_dollar then
            res[#res] = substr(res[#res], 1, #res[#res] - 1)
            print(substr(res[#res], 1, #res - 1))
            s = "$" .. "'" .. s .. "'"
        end

        if is_quoted then
            append(res, s)
        else
            extend(res, split(s, "%s+"))
        end
    end)

    return grep(res, function(x)
        return #x > 0
    end)
end

-- local test = [[xargs -i{} -d $'\n' echo "abcd ef {} \"hello\"" $acd $'']]
-- pp(shlex.parse(test))

return shlex
