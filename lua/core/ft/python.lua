local python = {}

python.formatter = {
  buffer = "cat {path} | black -q -",
  workspace = "black -q .",
  dir = "black -q .",
  stdin = true,
}

python.test = "pytest {path}"

python.repl = {
  buffer = "ipython3",
  workspace = "ipython3",
  dir = "python3",
  on_input = function(lines)
    return list.append(
      list.filter(lines, function(x)
        return #x > 0
      end),
      ""
    )
  end,
  load_from_path = function(fname, make_file)
    local new_fname = fname .. ".py"
    make_file(new_fname)

    return sprintf("%%load %s\n\n", new_fname)
  end,
}

python.server = "jedi_language_server"

python.compile = "python3 {path}"

python.buf_opts = {
  shiftwidth = 4,
  tabstop = 4,
  expandtab = true,
}

return python
