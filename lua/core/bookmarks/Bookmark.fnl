(if (not (. _G :Bookmark))
  (tset _G :Bookmark {:dest (path.join (vim.fn.stdpath :data) "bookmarks.lua")
                      :BOOKMARKS {}})

(lambda get-bufname [bufnr]
  (vim.api.nvim_buf_get_name bufnr))

(lambda resolve-path [p]
  (validate {:path [(is [:n :s]) p]})
  (if 
    (and (is_a p :string) 
         (path.exists p))
    (if (path.isdir p)
      {:path p :dir true} 
      {:path p})

    (is_a p :number)
    (let [bufnr (or (and (= p 0) (vim.fn.bufnr)) p)
          bufname (vim.api.nvim_buf_get_name p)]
      (if (= (length bufname) 0)
        nil
        {:path bufname
         :bufnr bufnr
         :dir (path.isdir bufname)
         :buffer true}))))

(lambda Bookmark.exists [p]
  (let [p (resolve-path p)]
    (if (not p)
      nil 
      (. Bookmark.BOOKMARKS (. p :path)))))

