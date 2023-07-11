local function nextheading()
  vim.cmd("normal! /^=\\{1,\\}$/")
end

local function prevheading()
  vim.cmd("normal! ?^=\\{1,\\}$/")
end

local function putstring(s, align)
  s = string.trim(array.to_array(s)[1])
  local linenum = vim.fn.line "."
  local line = vim.fn.getline(linenum):gsub(" *$", "")
  local len = #line
  local put = vim.api.nvim_put
  local slen = #s
  local bufnr = vim.fn.bufnr()
  local tw = vim.bo.textwidth

  if not align or (len >= tw or len + slen > tw) then
    buffer.setlines(bufnr, linenum - 1, linenum, array.concat { line, " ", s })
  elseif align then
    local spaceslen = tw - (len + slen)
    local spaces = string.rep(" ", spaceslen)
    s = array.concat { line, spaces, s }
    buffer.setlines(bufnr, linenum - 1, linenum, s)
  end
end

local function getprefix(prefix)
  prefix = prefix or buffer.var(buffer.bufnr(), "help_prefix")
  buffer.var(vim.fn.bufnr(), "help_prefix", prefix)
  return prefix
end

local function gettag() return input({ "tag", "Tag > " }).tag end

local function getstring(tag, ref, prefix, heading)
  prefix = prefix or getprefix(prefix) or ""

  if tag and ref then
    local ref = getstring(nil, tag)
    tag = getstring(tag)
    local tw = vim.bo.textwidth
    local spaceslen = tw - (#tag + #ref)
    local spaces = string.rep(" ", spaceslen)

    return array.concat { tag, spaces, ref }
  elseif tag and not heading then
    return array.concat { "*", tag, "*" }
  elseif tag then
    return array.concat { "*", prefix, ".", tag, "*" }
  elseif ref then
    return array.concat { "|", prefix, ".", ref, "|" }
  end
end

local function getsep() return string.rep("=", vim.bo.textwidth - 1) end

local function putsep()
  local line = buffer.row()

  buffer.setlines(buffer.bufnr(), line - 1, line, { getsep() })
end

local function putjump(s) putstring(getstring(s or gettag())) end

local function putref(s) putstring(getstring(nil, s or gettag())) end

local function putheading()
  local s = input({ "heading", "Heading" }, { "ref", "Reference" })

  local heading, ref = s.heading, s.ref
  heading = string.upper(heading)
  local cmd = vim.cmd

  s = {
    getsep(),
    getstring(s.heading:upper(), ref, nil, true),
    "",
  }

  local row = buffer.row()

  buffer.setlines(vim.fn.bufnr(), row - 1, row, s)
end

filetype.help = {
  extension = ".txt",

  hooks = {
    function (au)
      if buffer.name(au.buf):match(user.dir) then
        buffer.setvar(au.buf, 'help_prefix', 'postmodern')
      end
    end
  },

  bo = {
    formatoptions = "tqn",
    textwidth = 80,
    shiftwidth = 2,
    tabstop = 2,
  },

  kbd = {
    noremap = true,
    prefix = "<leader>m",

    { "-", putsep, "Put seperator" },
    { "|", putref, "Put reference" },
    { "*", putjump, "Put jump reference" },
    { "=", putheading, "Put heading" },
    {
      "p",
      function() getprefix(input({ "prefix", "Tag prefix" }).prefix) end,
      "Set tag prefix",
    },
  },
}
