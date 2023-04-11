require "core.bufgroups.BufGroup"

local get_path = function(ws, p)
  p = p:gsub("^/?", "")
  ws = ws:gsub("^/?", "")
  return path.join(os.getenv "HOME", ws, p)
end

-- user.bufgroups = user.bufgroups or {
user.bufgroups = {
  _pools = {},
  defaults = {
    pools = {
      scripting = {
        ruby_scripting = get_path("Scripts", "Ruby"),
        python_scripting = get_path("Scripts", "Python"),
        fennel_scripting = get_path("Scripts", "fennel"),
        ocaml_scripting = get_path("Scripts", "ocaml"),
        js_scripting = get_path("Scripts", "Javascript"),
        jl_scripting = get_path("Scripts", "Julia"),
        cl_scripting = get_path("Scripts", "CLisp"),
      },
      docs = {
        work = get_path("Work", ".+(tex|norg|txt)$"),
        docs = get_path("Documents", ".+(tex|norg|txt)$"),
      },
      langs = {
        python = "\\.py$",
        ruby = "\\.rb$",
        javascript = "\\.js$",
        ocaml = "\\.ml$",
        fennel = "\\.fnl",
        common_lisp = "\\.lisp",
      },
      nvim = {
        user = get_path(".nvim", ".+"),
        doom = get_path(".config/nvim", ".+"),
      },
    },
  },
}

local M = user.bufgroups
local pools = M._pools
local defaults = user.bufgroups.defaults

function M.create_default_pools(overwrite)
  overwrite = overwrite == nil and true or false

  dict.each(defaults.pools, function(name, groups)
    if not pools[name] or overwrite then
      pools[name] = BufGroupPool(name)
      local pool = pools[name]
      dict.each(groups, function(group, pat)
        pool:add(group, pat)
      end)
    end
  end)
end

M.create_default_pools()
