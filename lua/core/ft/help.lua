local function putstring(s, align)
  s = string.trim(array.tolist(s)[1])
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
  prefix = prefix or buffer.getvar(buffer.bufnr(), 'help_prefix')
  buffer.setvar(vim.fn.bufnr(), "help_prefix", prefix)
  return prefix
end

local function gettag() return input({ "tag", "Tag > " }).tag end

local function getstring(tag, ref, prefix, heading)
  prefix = prefix or getprefix(prefix) or ''

  if tag and ref then
    local ref = getstring(nil, tag)
    tag = getstring(tag)
    local tw = vim.bo.textwidth
    local spaceslen = tw - (#tag + #ref)
    local spaces = string.rep(' ', spaceslen - 1)

    return array.concat {tag, spaces, ref}
  elseif tag and not heading then
    return array.concat { "*", tag, "*" }
  elseif tag then
    return array.concat { "*", prefix, ".", tag, "*" }
  elseif ref then
    return array.concat { "|", prefix, ".", ref, "|" }
  end
end

local function getsep()
  return string.rep("=", vim.bo.textwidth - 1) 
end

local function putsep()
  local line = buffer.getrow()

  buffer.setlines(
    buffer.bufnr(),
    line - 1,
    line,
    { getsep() }
  )
end

local function putjump(s) 
  putstring(getstring(s or gettag())) 
end

local function putref(s)
  putstring(getstring(nil, s or gettag()))
end

local function putheading()
  local s = input(
    { "heading", "Heading" },
    { "ref", "Reference" }
  )

  local heading, ref = s.heading, s.ref
  heading = string.upper(heading)
  local cmd = vim.cmd

  s = {
    getsep(),
    getstring(s.heading:upper(), ref, nil, true),
    ""
  }

  local row = buffer.getrow()

  buffer.setlines(
    vim.fn.bufnr(), 
    row-1,
    row,
    s
  )
end

filetype.help = {
  extension = ".txt",
  hooks = { "autocmd BufWrite <buffer> :TrimWhiteSpace" },
  bo = {
    formatoptions = "tqn",
    textwidth = 80,
    shiftwidth = 2,
    tabstop = 2,
  },
  hooks = g,
  kbd = {
    noremap = true,
    prefix = "<leader>m",

    -- If line already dict.contains == then, reformat it
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
