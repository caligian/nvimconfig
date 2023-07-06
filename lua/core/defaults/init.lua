local function load_with_user(name)
    local ok, msg = pcall(require, 'core.defaults.' .. name)
    utils.require('user.' .. name)

    if ok and is_a.callable(msg) then
        msg()
    end
end

local function load_all()
    local dest = path.join(user.dir, 'lua', 'core', 'defaults')
    local files = dir.getallfiles(dest)

    array.each(files, function (x)
        if x:match 'init' then return end

        x = path.basename(x)
        if not x:match_any('lua$', '^[a-zA-Z0-9_-]+$') then return end

        x = x:gsub('%.lua$', '')

        load_with_user(x)
    end)
end

load_all()
