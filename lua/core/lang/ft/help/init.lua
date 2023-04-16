local function put_sep(respect_tw)
  local bufnr = vim.fn.bufnr()
  local linenum = vim.fn.line "."
  local line = vim.fn.getline(linenum)
  local w = vim.bo.textwidth

  if not respect_tw then
    local wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1]
    w = vim.o.columns - wininfo.textoff
  end
  local sep = string.rep("=", w < 5 and 5 or w)

  if line:match "^==" then
    vim.api.nvim_buf_set_lines(bufnr, linenum - 1, linenum, false, { sep })
  else
    vim.api.nvim_put({ sep }, "c", true, true)
  end
end

local function put_ref(jump)
  local bufnr = vim.fn.bufnr()
  local linenum = vim.fn.line "."
  local line = trim(vim.fn.getline(linenum))

  if #line == 0 or line:match "^====" then
    nvimerr "Cannot put a tag on an empty line or a separator line"
    return
  end

  if line:match "[|*][^|*]+[|*]" then
    line = line:gsub(" *[|*][^|*]+[|*]", "")
  end

  local ok, prefix = pcall(vim.api.nvim_buf_get_var, bufnr, "_tag_prefix")
  prefix = ok and prefix or false
  local tag = vim.fn.input "Tag name: "
  if prefix then
    tag = prefix .. "_" .. tag
  end

  local l = #tag
  if l == 0 then
    return
  end

  local tw = vim.bo.textwidth
  local pos = tw - l
  if pos < 5 then
    pos = 5
  end

  local line_l = #line
  if line_l > pos then
    return
  end

  local spaces_l = pos - line_l
  local new = { line, string.rep(" ", spaces_l) }
  if jump then
    array.append(new, "|" .. tag .. "|")
  else
    array.append(new, "*" .. tag .. "*")
  end
  new = { concat(new, "") }

  vim.api.nvim_buf_set_lines(bufnr, linenum - 1, linenum, false, new)
end

Lang("help", {
  bo = {
    formatoptions = "tqn",
    textwidth = 80,
    shiftwidth = 2,
    tabstop = 2,
  },
  hooks = function()
    vim.cmd [[ autocmd BufWrite <buffer> :TrimWhiteSpace ]]
  end,
  kbd = {
    { noremap = true, prefix = "<leader>m" },

    -- If line already dict.contains == then, reformat it
    { "+", put_sep, "Put seperator: =" },
    { "=", partial(put_sep, true), "Put seperator (tw): =" },
    { "|", partial(put_ref, true), "Put reference" },
    { "*", put_ref, "Put jump reference" },
    {
      "p",
      function()
        local prefix = vim.fn.input "Tag prefix: "
        if #prefix == 0 then
          return
        end
        vim.api.nvim_buf_set_var(vim.fn.bufnr(), "_tag_prefix", prefix)
      end,
      "Set tag prefix",
    },
  },
})
