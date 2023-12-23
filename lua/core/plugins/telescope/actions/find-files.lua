local function get_fname(sel)
  return sel.cwd .. "/" .. sel[1]
end

local mod = {
  delete = function(prompt_bufnr)
    local _ = require "core.utils.telescope"()
    local sel = _:selected(prompt_bufnr, true)

    list.each(sel, function(x)
      x = get_fname(x)
      print("rm -r " .. x)
      print(vim.fn.system { "rm", "-r", x })
    end)
  end,
  touch_and_open = function(prompt_bufnr)
    local _ = require "core.utils.telescope"()
    _.actions.close(prompt_bufnr)

    local filename = vim.fn.input "touch file % "
    if #filename == 0 then
      return
    end

    if filename:match "/$" then
      vim.fn.system { "mkdir", "-p", filename }
    else
      vim.fn.system { "touch", filename }
    end

    vim.cmd(":e " .. filename)
  end,
  touch = function(prompt_bufnr)
    local _ = require "core.utils.telescope"()
    _.actions.close(prompt_bufnr)

    local filename = vim.fn.input "touch file % "
    if #filename == 0 then
      return
    end

    if filename:match "/$" then
      vim.fn.system { "mkdir", "-p", filename }
    else
      vim.fn.system { "touch", filename }
    end
  end,
}

return mod
