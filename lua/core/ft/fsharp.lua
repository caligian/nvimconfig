local fsharp = Filetype "fsharp"

fsharp.repl = {
    "dotnet fsi",
    on_input = function(s)
        local has = array.grep(s, function(x)
            return #x ~= 0
        end)
        local n = #has
        local lst = has[n]
        if not lst:match ";; *$" then
            has[n] = lst .. ";;"
        end

        return has
    end,
}

fsharp.compile = "dotnet fsi"

return fsharp
