require "core.bufgroups.Bufgroup"
require 'core.bufgroups.Pool'

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
        ruby = {'BufRead', get_path("Scripts", "Ruby")},
        tcl = {'BufRead', get_path("Scripts", "Tcl")},
        python = {'BufRead', get_path("Scripts", "Python")},
        hy = {'BufRead', get_path("Scripts", "hy")},
        fennel = {'BufRead', get_path("Scripts", "fennel")},
        ocaml = {'BufRead', get_path("Scripts", "ocaml")},
        javascript = {'BufRead', get_path("Scripts", "Javascript")},
        julia = {'BufRead', get_path("Scripts", "Julia")},
        common_lisp = {'BufRead', get_path("Scripts", "CLisp")},
      },
      docs = {
        work = {'BufRead', get_path("Work", ".+(tex|norg|txt)}$")},
        docs = {'BufRead', get_path("Documents", ".+(tex|norg|txt)}$")},
      },
      langs = {
        python = {'BufRead', "\\.py$"},
        ruby = {'BufRead', "\\.rb$"},
        javascript = {'BufRead', "\\.js$"},
        ocaml = {'BufRead', "\\.ml$"},
        fennel = {'BufRead', "\\.fnl"},
        common_lisp = {'BufRead', "\\.lisp"},
      },
      nvim = {
        user = {'BufRead', get_path(".nvim", ".+")},
        doom = {'BufRead', get_path(".config/nvim", ".+")},
      },
    },
  },
}

req 'user.bufgroups'
local M = user.bufgroups
local pools = Bufgroup.POOLS
local defaults = user.bufgroups.defaults

function M.setup(overwrite)
  overwrite = overwrite == nil and true or false

  dict.each(defaults.pools, function(pool, groups)
    if not pools[pool] or overwrite then
      pool = BufgroupPool(pool)
      dict.each(groups, function(group, args)
        pool:add(group, unpack(args))
      end)
    end
  end)
end

M.setup()
