user.lang.langs = user.lang.langs or {}
local lang = user.lang

function lang.hook(ft, callback)
    local l
    if not user.lang[ft] then
        V.makepath(user.lang.langs, ft)
        l = user.lang.langs[ft]
    end
    V.makepath(l, 'hooks')
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

local src = path.join(vim.fn.stdpath('config'), 'lua', 'core', 'lang', 'ft')
for _, d in ipairs(dir.getdirectories(src)) do
    d = path.basename(d)
    local config = V.require('core.lang.ft.' .. d)
    if config then
        user.lang.langs[d] = config
    end
end
