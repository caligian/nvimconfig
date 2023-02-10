if not V then
	V = {}
end
if not V.globals then
	V.globals = {}
end
if not V.logs then
	V.logs = {}
end

--
require("utils.utils")
require("utils.autocmd")
require("utils.kbd")
require("utils.buffer")
require("utils.process")
require("utils.color")
