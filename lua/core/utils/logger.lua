require "core.utils.buffer"

logger = logger or {}
logger.path = path.join(os.getenv "HOME", ".local", "share", "nvim", "messages")
logger.bufname = logger.path

if not logger.bufnr or not buffer.exists(logger.bufnr) then
    logger.bufnr = buffer.bufadd(logger.bufname)
end

function logger.write(s)
    buffer.set_lines(logger.bufnr, -1, -1, s)
    buffer.save(logger.bufnr)
end

function logger.split(direction)
    buffer.split(logger.bufnr, direction)
end

function logger.log(level, s)
    if is_string(s) then
        s = string.split(s, "[\n\r]")
    end

    s = array.unshift(s, sprintf("[%s]", string.upper(level)))
    s = array.append(s, "")

    logger.write(s)
end

function logger.warn(s)
    logger.log("warn", s)
end

function logger.info(s)
    logger.log("info", s)
end

function logger.pcall(f, args, on_failure)
    args = args or {}
    args = array.to_array(args)
    local ok, msg = pcall(f, unpack(args))

    if not ok then
        msg = sprintf(
            "%s: %s: %s > failed with args: %s",
            logger.get_path(3),
            logger.get_line(3),
            logger.get_caller(3),
            dump(args)
        )

        logger.info(msg)

        if on_failure then
            return on_failure(msg, f, args)
        end
    end

    return msg or true
end

function logger.require(req, on_failure)
    return logger.pcall(require, req, on_failure)
end

function logger.get_path(level)
    return debug.getinfo(level or 2, "S").source
end

function logger.get_line(level)
    return debug.getinfo(level or 2, "l").currentline
end

function logger.get_caller(level)
    return debug.getinfo(level or 2, 'n').name
end

vim.keymap.set("n", "<space>hl", logger.split, { desc = "split show logs" })
vim.keymap.set("n", "<space>hL", partial(logger.split, "v"), { desc = "vsplit show logs" })
vim.keymap.set({"i", "n"}, "q", ':hide<CR>', {buffer = logger.bufnr})
