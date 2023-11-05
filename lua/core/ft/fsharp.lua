local fsharp = filetype("fsharp")

fsharp.repl = {
    "dotnet fsi",
    on_input = function(s)
        local has = s, function(x)
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

fsharp.compile = "dotnet fsi %s"

return fsharp
