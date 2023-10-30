local racket = plugin.get("racket")
racket.repl = "racket"
racket.compile = "racket %s"
racket.lsp_server = "racket_langserver"

return racket


