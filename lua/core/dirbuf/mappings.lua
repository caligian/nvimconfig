function Dirbuf:set_default_mappings()
  self.mappings.cd = self:noremap("n", "C", function()
    self:cursor_cd()
  end, "cd")

  self.mappings.unmark_all = self:noremap("n", "U", function()
    self:unmark_all_paths()
  end, "unmark all paths")

  self.mappings.show_marked = self:noremap("n", "P", function()
    tostderr(join(self:get_marked_paths(), "\n"))
  end, "display marked path")

  self.mappings.print_filename = self:noremap("n", "p", function()
    pp(self:get_path_at_cursor())
  end, "display path")

  self.mappings.unmark = self:noremap("n", "u", function()
    self:unmark_path_at_cursor()
    vim.cmd 'normal! j'
  end, "unmark child at cursor")

  self.mappings.go_back = self:noremap("n", "-", function()
    local bufname = Buffer.name(Buffer.current())
    bufname = bufname:gsub('^Dirbuf:', '')
    local go_back_to = Path.dirname(bufname)

    if not go_back_to then
      return
    elseif not go_back_to then
      tostderr('reached end of tree')
    else
      if go_back_to == '/' then
        if os.getenv('USER') ~= 'root' then
          tostderr('cannot traverse / without sudo')
          return
        end
      end

      local obj = Dirbuf(go_back_to)
      self:hide()
      obj:show()
    end
  end, "mark child at cursor")

  self.mappings.enter_path = self:noremap("n", "<CR>", function()
    local row, p = self:get_path_at_cursor()

    if row < 3 then
      vim.cmd('normal! 3G')
      return
    end

    if not p then
      return
    elseif Path.is_dir(p) then
      local obj = Dirbuf(p)
      self:hide()
      obj:show()
    else
      tostderr('not a dir: ' .. tostring(p))
    end
  end, "mark child at cursor")

  self.mappings.mark = self:noremap("n", "<Tab>", function()
    self:mark_path_at_cursor()
    vim.cmd 'normal! j'
  end, "mark child at cursor")

  return self.mappings
end


