local nf = require "notify"
local notify = plugin.get "notify"

notify.config = {
    background_colour = "NotifyBackground",
    fps = 30,
    icons = {
        DEBUG = "[Debug]",
        ERROR = "ERROR",
        INFO = "[Info]",
        TRACE = "[Trace]",
        WARN = "WARNING",
    },
    level = 2,
    minimum_width = 50,
    render = "default",
    stages = "fade_in_slide_out",
    timeout = 5000,
    top_down = true,
}

function notify:setup()
    nf.setup(self.config)
end

function notify.dismiss_all()
    nf.dismiss { pending = true, silent = true }
end

function notify.show_history()
    local bufnr = buffer.create_empty()
    local history = nf.history()

    if #history == 0 then
        nf.notify('No notifications have been displayed yet')
        return
    end

    local notifications = string.split(dump(nf.history()), "\n")
    buffer.map(bufnr, "n", "q", ":hide<CR>", { desc = "hide buffer", silent = true })
    buffer.set_lines(bufnr, 0, -1, notifications)
    buffer.float(bufnr, { center = { 80, 30 } })
    buffer.autocmd(bufnr, "WinLeave", function() buffer.wipeout(bufnr) end)
end

function notify.say(...)
    nf.notify(...) 
end

notify.mappings = {
    opts = {silent=true, noremap=true},
    { "<leader>hn", notify.show_history, {desc = 'show notification history', name = 'show_history'} },
    { "<leader>hN", notify.dismiss_all, {desc = 'hide notifications', name = 'hide_notifications'} },
}
