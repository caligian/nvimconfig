local lisp = filetype("lisp")
lisp.repl = "rebar3 lfe repl"
lisp.filetype = { extension = { lfe = "lisp" } }

local function run_command(cmd, prompt)
    return function()
        if prompt then
            local show = input { prompt = { prompt } }
            if not show.prompt then
                error(prompt .. "no input provided")
            else
                cmd = cmd .. " " .. show.prompt
            end
        end

        local proc = Process(cmd, {
            on_stdout = true,
            on_stderr = true,
            on_exit = function(proc)
                if proc.stderr then
                    say(proc.stderr, "\n"))
                    return
                end

                if proc.stdout then
                    say(proc.stdout, "\n"))
                end
            end,
        })
    end
end

lisp.mappings = {
    opts = { leader = true, noremap = true, prefix = "m" },
    new = { "n", run_command("rebar3 lfe new", "rebar3 lfe new NAME-{lib, main, escript, app, release} % ") },
    compile = { "c", run_command "rebar3 lfe compile" },
    test = { "t", run_command "rebar3 lfe test" },
    run = { "m", run_command "rebar3 lfe run" },
    release = { ".", run_command "rebar3 lfe release" },
    clean = { "k", run_command "rebar3 lfe clean" },
    versions = { "v", run_command "rebar3 lfe versions" },
}

return lisp
