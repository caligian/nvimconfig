local function homepath(x)
  return path.join(os.getenv "HOME", x)
end

local function langpath(x)
  return path.join(homepath "Scripts", x)
end

BufferGroup.defaults = {
  nvim = {
    builtin = user.dir,
    user = user.user_dir
  },
  scripting = {
    python = langpath 'python',
    lua51 = langpath 'lua51',
    lua54 = langpath 'lua54',
    lua53 = langpath 'lua52',
    lua = langpath 'lua',
    ruby = langpath 'ruby',
    cs = langpath 'cs',
    julia = langpath 'julia'
  },
  projects = {
    main = homepath 'Projects'
  },
  work = {
    main = homepath 'Work'
  }
}

BufferGroup.mappings = {
  noremap = true,
  leader = true,
  {
    ".",
    BufferGroup.runbufpicker,
    { desc = "Buffer picker", name = "BufferGroup.buffer_picker" },
  },
  {
    ":",
    BufferGroup.runmainpicker,
    { desc = "Pool picker", name = "BufferGroup.main_picker" },
  },
}
