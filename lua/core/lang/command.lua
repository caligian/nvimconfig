local function get_langs()
  Lang.loadall()
  return table.keys(Lang.langs)
end

local function parse(args)
  local blank = table.isblank(args.fargs)
  if not blank then
    return args.fargs
  end
  return false
end

utils.command("LangLoad", function(args)
  args = parse(args)
  if not args then
    return
  end
  table.each(args, Lang.load)
end, { nargs = "+", complete = get_langs })
