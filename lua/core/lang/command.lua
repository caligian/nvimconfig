local function get_langs()
  Lang.loadall()
  return dict.keys(Lang.langs)
end

local function parse(args)
  local blank = dict.isblank(args.fargs)
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
  array.each(args, Lang.load)
end, { nargs = "+", complete = get_langs })
