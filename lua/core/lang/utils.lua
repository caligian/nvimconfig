local lang = user.lang
lang.callbacks = lang.callbacks and {}

function lang.hook(ft, callback)
  local l = { hooks = {} }
  if not user.lang[ft] then
    V.makepath(user.lang.langs, ft)
    l = user.lang.langs[ft]
  end
  local group = 'hooks_for_filetype_' .. ft
  local au = user.autocmd(group, false)

  -- Save all callbacks in a list
  -- This will make it easier to run callbacks without removing autocmds
  V.append(l.hooks, callback)
  if #l.hooks > 0 then
    callback = function()
      for _, hook in ipairs(l.hooks) do
        hook()
      end
    end
    au:create('FileType', ft, callback)
  end
end
