local lspsaga = {}

lspsaga.config = {
  ui = {
    code_action = "?",
  },
}

local opts = {
  leader = true,
  prefix = "l",
  silent = true,
  noremap = true,
}

lspsaga.mappings = {
  line_diag = {
    "n",
    "<A-k>",
    "<cmd>Lspsaga show_line_diagnostics<CR>",
    { desc = "line diagnostics" },
  },

  doc = {
    "n",
    "K",
    "<cmd>Lspsaga hover_doc<CR>",
    { desc = "hover doc" },
  },

  next_diag = {
    "n",
    "]e",
    "<cmd>Lspsaga diagnostic_jump_next<CR>",
    { desc = "next diag" },
  },

  prev_diag = {
    "n",
    "[e",
    "<cmd>Lspsaga diagnostic_jump_prev<CR>",
    { desc = "prev diag" },
  },

  finder = {
    "n",
    "f",
    ":Lspsaga finder ref<CR>",
    opts,
  },

  outgoing = {
    "n",
    "I",
    ":Lspsaga outgoing_calls<CR>",
    opts,
  },

  incoming = {
    "n",
    "i",
    ":Lspsaga incoming_calls<CR>",
    opts,
  },

  actions = {
    "n",
    "a",
    ":Lspsaga code_action<CR>",
    opts,
  },

  peek = {
    "n",
    "p",
    ":Lspsaga peek_definition<CR>",
    opts,
  },

  peek_type = {
    "n",
    "P",
    ":Lspsaga peek_type_definition<CR>",
    opts,
  },

  rename = {
    "n",
    "/",
    "<cmd>Lspsaga rename<CR>",
    opts,
  },

  project_replace = {
    "n",
    "%",
    ":Lspsaga project_replace",
    opts,
  },

  outline = {
    "n",
    "o",
    "<cmd>Lspsaga outline<CR>",
    opts,
  },

  buf_diags = {
    "n",
    "d",
    "<cmd>Lspsaga show_buf_diagnostics ++float<CR>",
    opts,
  },

  diags = {
    "n",
    "D",
    "<cmd>Lspsaga show_workspace_diagnostics ++float<CR>",
    opts,
  },
}

function lspsaga:setup()
  require("lspsaga").setup(lspsaga.config)
end

return lspsaga
