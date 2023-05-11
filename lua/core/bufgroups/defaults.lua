local Bufgroup = require "core.utils.Bufgroup"
-- Bufgroup = loadfile('Bufgroup.lua')()

local get_path = function(ws, p)
  p = p:gsub("^/?", "")
  ws = ws:gsub("^/?", "")
  return path.join(os.getenv "HOME", ws, p)
end

user.bufgroup.enable = {
  scripting = {
    ruby = { "BufRead", get_path("Scripts", "Ruby") },
    tcl = { "BufRead", get_path("Scripts", "Tcl") },
    python = { "BufRead", get_path("Scripts", "Python") },
    hy = { "BufRead", get_path("Scripts", "hy") },
    fennel = { "BufRead", get_path("Scripts", "fennel") },
    ocaml = { "BufRead", get_path("Scripts", "ocaml") },
    javascript = { "BufRead", get_path("Scripts", "Javascript") },
    julia = { "BufRead", get_path("Scripts", "Julia") },
    common_lisp = { "BufRead", get_path("Scripts", "CLisp") },
  },
  docs = {
    work = { "BufRead", get_path("Work", ".+(tex|norg|txt)$") },
    docs = { "BufRead", get_path("Documents", ".+(tex|norg|txt)$") },
  },
  langs = {
    python = { "BufRead", "\\.py$" },
    ruby = { "BufRead", "\\.rb$" },
    javascript = { "BufRead", "\\.js$" },
    ocaml = { "BufRead", "\\.ml$" },
    fennel = { "BufRead", "\\.fnl" },
    common_lisp = { "BufRead", "\\.lisp" },
  },
  nvim = {
    user = { "BufRead", get_path(".nvim", ".+") },
    doom = { "BufRead", get_path(".config/nvim", ".+") },
  },
}

dict.each(user.bufgroup.enable, function(pool, groups)
  dict.each(groups, function(group_name, spec)
    if not Bufgroup.get(pool .. "." .. group_name) then
      Bufgroup(group_name, unpack(array.append(spec, pool))):enable()
    end
  end)
end)

req "user.bufgroups"
