require "core.utils.au"
require "core.utils.buffer"
require "core.utils.win"
require "core.utils.kbd"
require "core.utils.job"

--- @alias lang.commandspec string|table|fun(path:string): string
--- @alias lang.mapping table<string,list>
--- @alias lang.autocmd table<string,fun(table)>

--- @class lang
--- @field langs table<string,lang>
--- @field on table see `:help vim.filetype`
--- @field linters string|string[]|lang.linters[] or a combination of any
--- @field server lang.server
--- @field formatter lang.formatter
--- @field compile lang.command
--- @field build lang.command
--- @field test lang.command
--- @field mappings lang.mapping
--- @field autocmds lang.autocmd
--- @field bo table<string,any> buffer options
--- @field wo table<string,any> window options
--- @field repl table
--- @field jobs table<string,job> jobs for this filetype
--- @field lsp table<string,function> lsp utils
--- @overload fun(string): lang

--- @class lang.command
--- @field buffer lang.commandspec
--- @field workspace lang.commandspec
--- @field dir lang.commandspec

--- @class lang.formatter : lang.command
--- @field stdin boolean
--- @field append_filename boolean

--- @class lang.repl : lang.command
--- @field on_input fun(lines:string[]): string[]
--- @field loadfile fun(path:string, mkfile:fun(p: string))

--- @class lang.linters
--- @field config table linter config

--- @class lang.server
--- @field config table lsp server config

lang = lang or class "lang"
lang.langs = lang.langs or {}
lang.jobs = lang.jobs or {}

--- @class lsp
--- @field diagnostic table<string,any> diagnostic config for vim.lsp
--- @field mappings table
lang.lsp = module()
local lsp = lsp
lsp.diagnostic = { virtual_text = false, underline = false, update_in_insert = false }

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = "single",
  title = "hover",
})

vim.diagnostic.config(lsp.diagnostic)

lsp.mappings = lsp.mappings
  or {
    float_diagnostic = {
      "<leader>li",
      partial(vim.diagnostic.open_float, { scope = "l", focus = false }),
      { desc = "LSP diagnostic float", noremap = true, leader = true },
    },
    previous_diagnostic = {
      "[d",
      vim.diagnostic.gotoprev,
      { desc = "LSP go to previous diagnostic", noremap = true, leader = true },
    },
    next_diagnostic = {
      "]d",
      vim.diagnostic.gotonext,
      { desc = "LSP go to next diagnostic", noremap = true, leader = true },
    },
    set_loclist = {
      "lq",
      vim.diagnostic.setloclist,
      { desc = "LSP set loclist", noremap = true, leader = true },
    },
    buffer_declarations = {
      "gD",
      vim.lsp.buf.declaration,
      { desc = "Buffer declarations", silent = true, noremap = true },
    },
    buffer_definitions = {
      "gd",
      vim.lsp.buf.definition,
      { desc = "Buffer definitions", silent = true, noremap = true },
    },
    float_documentation = {
      "K",
      vim.lsp.buf.hover,
      { desc = "Show float UI", silent = true, noremap = true },
    },
    implementations = {
      "gi",
      vim.lsp.buf.implementation,
      { desc = "Show implementations", silent = true, noremap = true },
    },
    signatures = {
      "<C-k>",
      vim.lsp.buf.signature_help,
      { desc = "Signatures", silent = true, noremap = true },
    },
    add_workspace_folder = {
      "<leader>lwa",
      vim.lsp.buf.add_workspace_folder,
      { desc = "Add workspace folder", silent = true, noremap = true },
    },
    remove_workspace_folder = {
      "<leader>lwr",
      vim.lsp.buf.remove_workspace_folder,
      { desc = "Remove workspace folder", silent = true, noremap = true },
    },
    list_workspace_folders = {
      "<leader>lwl",
      function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end,
      { desc = "List workspace folders", silent = true, noremap = true },
    },
    type_definition = {
      "<leader>lD",
      vim.lsp.buf.type_definition,
      { desc = "Show type definitions", silent = true, noremap = true },
    },
    buffer_rename = {
      "<leader>lR",
      vim.lsp.buf.rename,
      { desc = "Rename buffer", silent = true, noremap = true },
    },
    code_action = {
      "<leader>la",
      vim.lsp.buf.code_action,
      { desc = "Show code actions", silent = true, noremap = true },
    },
    buffer_references = {
      "gr",
      vim.lsp.buf.references,
      { desc = "Show buffer references", silent = true, noremap = true },
    },
  }

---@diagnostic disable-next-line: inject-field
function lsp.fix_omnisharp(client, _)
  client.server_capabilities.semanticTokensProvider = {
    full = vim.empty_dict(),
    legend = {
      tokenModifiers = { "static_symbol" },
      tokenTypes = {
        "comment",
        "excluded_code",
        "identifier",
        "keyword",
        "keyword_control",
        "number",
        "operator",
        "operator_overloaded",
        "preprocessor_keyword",
        "string",
        "whitespace",
        "text",
        "static_symbol",
        "preprocessor_text",
        "punctuation",
        "string_verbatim",
        "string_escape_character",
        "class_name",
        "delegate_name",
        "enum_name",
        "interface_name",
        "module_name",
        "struct_name",
        "type_parameter_name",
        "field_name",
        "enum_member_name",
        "constant_name",
        "local_name",
        "parameter_name",
        "method_name",
        "extension_method_name",
        "property_name",
        "event_name",
        "namespace_name",
        "label_name",
        "xml_doc_comment_attribute_name",
        "xml_doc_comment_attribute_quotes",
        "xml_doc_comment_attribute_value",
        "xml_doc_comment_cdata_section",
        "xml_doc_comment_comment",
        "xml_doc_comment_delimiter",
        "xml_doc_comment_entity_reference",
        "xml_doc_comment_name",
        "xml_doc_comment_processing_instruction",
        "xml_doc_comment_text",
        "xml_literal_attribute_name",
        "xml_literal_attribute_quotes",
        "xml_literal_attribute_value",
        "xml_literal_cdata_section",
        "xml_literal_comment",
        "xml_literal_delimiter",
        "xml_literal_embedded_expression",
        "xml_literal_entity_reference",
        "xml_literal_name",
        "xml_literal_processing_instruction",
        "xml_literal_text",
        "regex_comment",
        "regex_character_class",
        "regex_anchor",
        "regex_quantifier",
        "regex_grouping",
        "regex_alternation",
        "regex_text",
        "regex_self_escaped_character",
        "regex_other_escape",
      },
    },
    range = true,
  }
end

function lsp.attach_formatter(client)
  require("lsp-format").on_attach(client)
end

function lsp.on_attach(client, bufnr)
  if client.name == "omnisharp" then
    lsp.fix_omnisharp(client)
  else
    buffer.set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

    local ft = vim.bo.filetype
    local has_formatter = lang(ft)
    if has_formatter and not has_formatter.formatter then
      lsp.attach_formatter(client)
    end

    local mappings = deepcopy(lsp.mappings)
    for _, value in pairs(mappings) do
      value.buffer = bufnr
    end

    kbd.map_groups(mappings)
  end
end

function lsp.setup_server(server, opts)
  opts = opts or {}
  local capabilities = opts.capabilities or require("cmp_nvim_lsp").default_capabilities()
  local on_attach = opts.on_attach or lsp.on_attach
  local flags = opts.flags or lsp.flags
  local default_conf = { capabilities = capabilities, on_attach = on_attach, flags = flags }

  default_conf = dict.merge(default_conf, opts)

  if default_conf.cmd then
    default_conf.cmd = tolist(default_conf.cmd)
  end

  require("lspconfig")[server].setup(default_conf)
end

function lang:islang()
  return typeof(x) == "lang"
end

function lang:init(name)
  if lang.islang(name) then
    return name
  elseif istable(name) then
    assert(name.name, "name is missing in " .. dump(name))
    local l = lang(name.name)
    dict.merge(l, name)

    lang.langs[name.name] = l
    return l
  elseif isnumber(name) then
    assert(buffer.exists(name), "invalid buffer " .. name)
    return lang(buffer.filetype(name))
  else
    local l = lang.langs[name]
    if l then
      return l
    end
  end

  self.name = name

  return self
end

function lang:fromdict(specs)
  local name = specs.name
  local x = lang(name)
  dict.merge(x, specs)

  return x
end

function lang:setbo(bo)
  bo = bo or self.bo
  asserttype(bo, "table")

  self:autocmd(function(opts)
    buffer.set_option(opts.buf, bo)
  end)
end

function lang:setwo(wo)
  wo = wo or self.wo
  asserttype(wo, "table")

  self:autocmd(function(opts)
    local winnr = buffer.winnr(opts.buf)
    if winnr then
      win.set_option(winnr, wo)
    end
  end)
end

--- @param specs? string|{ [1]: string, config: table }
function lang:setup_lsp(specs)
  specs = specs or self.server
  specs = isstring(specs) and { specs } --[[@as table]]

  if not specs then
    return
  end

  lsp.setup_server(specs[1], specs.config)

  return self
end

function lang:getjob(name, noprefix)
  if not name then
    return
  end

  name = not noprefix and ("filetype." .. self.name .. "." .. name) or name
  return self.jobs[name]
end

local function find_workspace(start_dir, pats, maxdepth, _depth)
  maxdepth = maxdepth or 5
  _depth = _depth or 0
  pats = tolist(pats or "%.git$")

  if maxdepth == _depth then
    return false
  end

  if not path.isdir(start_dir) then
    return false
  end

  local parent = path.dirname(start_dir)
  local children = dir.getfiles(start_dir)

  for i = 1, #pats do
    local pat = pats[i]

    for j = 1, #children do
      if children[j]:match(pat) then
        return children[j]
      end
    end
  end

  return find_workspace(parent, pats, maxdepth, _depth + 1)
end

function lang:query(attrib, f)
  self = lang(self)

  if self[attrib] then
    return f and f(self[attrib]) or self[attrib]
  end
end

function lang.workspace(bufnr, pats, maxdepth, _depth)
  bufnr = bufnr or buffer.bufnr()
  if isstring(bufnr) then
    bufnr = buffer.bufnr(bufnr)
  end

  if not buffer.exists(bufnr) then
    return false
  end

  local lspconfig = require "lspconfig"
  ---@diagnostic disable-next-line: param-type-mismatch
  local server = lang.query(buffer.filetype(bufnr), "server")
  local bufname = buffer.name(bufnr)

  if server then
    assertisa(server, union("string", "table"))
    local config = isstring(server) and lspconfig[server] or lspconfig[server[1]]
    local root_dir_checker = config.document_config.default_config.root_dir
    if not config.get_root_dir then
      return find_workspace(bufname, pats, maxdepth, _depth)
    elseif root_dir_checker then
      return root_dir_checker(bufname)
    end

    return config.get_root_dir(bufname)
  else
    return find_workspace(bufname, pats, maxdepth, _depth)
  end
end

function lang:command(bufnr, action)
  action = action or "compile"
  local validactions = { "compile", "build", "test", "repl", "formatter" }

  params {
    buffer = { "number", bufnr },
    action = {
      function(x)
        return list.contains(validactions, x)
      end,
      action,
    },
  }

  assert(buffer.exists(bufnr), "invalid buffer: " .. dump(bufnr))

  local bufname = buffer.name(bufnr)
  local compile = self[action]
  local spec = union("string", "table", "function")

  if not compile then
    return
  else
    assert(isa[spec](compile))
  end

  if not istable(compile) then
    compile = { buffer = spec }
  end

  params {
    compile = {
      {
        __extra = true,
        ["1?"] = spec,
        ["buffer?"] = spec,
        ["workspace?"] = spec,
        ["dir?"] = spec,
      },
      compile,
    },
  }

  local function getfromtable(X, what)
    for key, value in pairs(X) do
      if what:match(key) then
        return value
      end
    end
  end

  local function dwim(X, what)
    if isfunction(X) then
      return X(what)
    elseif isstring(X) then
      return X
    else
      return getfromtable(X, what)
    end
  end

  local out = dict.filter(compile, function(k, v)
    return (k ~= "buffer" and k ~= "workspace" and k ~= "dir" and k ~= 1) and v
  end)

  if compile[1] or compile.buffer then
    local cmd = dwim(compile[1] or compile.buffer, bufname)
    if cmd then
      out.buffer = { cmd, bufname }
    end
  end

  if compile.dir then
    local d = path.dirname(bufname)
    local cmd = dwim(compile.dir, d)
    if cmd then
      out.dir = { cmd, d }
    end
  end

  if compile.workspace then
    local ws = lang.workspace(bufnr)
    if ws then
      local cmd = dwim(compile.workspace, ws)
      if cmd then
        out.workspace = { cmd, ws }
      end
    end
  end

  if size(out) == 0 then
    error(self.name .. "." .. action .. ": no commands exist")
  end

  return out
end

function lang:format(bufnr, opts)
  opts = opts or {}
  local config = self:command(bufnr, "formatter")
  opts = copy(opts)
  local stdin = opts.stdin or config.stdin
  local write = opts.write or config.write
  local append_filename = opts.append_filename or config.append_filename
  local bufname = buffer.name(bufnr)
  local name

  if opts.dir then
    name = self.name .. ".formatter.dir."
  elseif opts.workspace then
    name = self.name .. ".formatter.workspace."
  else
    name = self.name .. ".formatter.buffer."
  end

  name = name .. bufname

  local function createcmd(tp)
    assert(config[tp], self.name .. ".formatter." .. tp .. ": no command exists")

    local cmd, target = unpack(config[tp])
    cmd = isa.list(args) and (cmd .. " " .. join(args, " ")) or cmd

    if tp == "buffer" then
      if append_filename == nil and stdin == nil then
        stdin = true
      end

      if append_filename then
        cmd = cmd .. " " .. target
      elseif stdin then
        cmd = sprintf('sh -c "cat %s | %s"', target, cmd)
      elseif cmd:match "%%path" then
        cmd = cmd:gsub("%%path", target)
      else
        cmd = cmd .. " " .. target
      end
    else
      if cmd:match "%%path" then
        cmd = cmd:gsub("%%path", target)
      else
        cmd = cmd .. " " .. target
      end
    end

    return cmd, target
  end

  local cmd, target
  if opts.workspace then
    cmd = createcmd "workspace"
  elseif opts.dir then
    cmd = createcmd "dir"
  else
    cmd = createcmd "buffer"
  end

  local winnr = buffer.winnr(bufnr)
  local view = winnr and win.save_view(winnr)
  opts.args = {}

  local proc = lang.job(cmd, {
    name = name,
    cwd = (opts.workspace or opts.dir) and target or path.dirname(bufname),
    before = function()
      vim.cmd(":w! " .. bufname)
      buffer.set_option(bufnr, "modifiable", false)
    end,
    on_exit = function(x)
      if x.exit_code ~= 0 then
        buffer.set_option(bufnr, "modifiable", true)

        local err = #x.errors > 1 and x.errors or #x.lines > 1 and x.lines
        if err then
          ---@diagnostic disable-next-line: cast-local-type
          err = join(err, "\n")
          tostderr(err)
        else
          print("check source syntax for buffer " .. bufname)
        end

        return
      end

      buffer.set_option(bufnr, "modifiable", true)

      local err = x.errors
      if #err > 0 then
        tostderr(join(err, "\n"))
        return
      end

      local out = x.lines
      if not out or #out == 0 then
        return
      else
        buffer.set_lines(bufnr, 0, -1, out)
      end

      if view then
        win.restore_view(winnr, view)
      end
    end,
  })

  return proc
end

function lang:format_dir(bufnr, opts)
  opts = opts or {}
  opts.dir = true
  return self:format(bufnr, opts)
end

function lang:format_workspace(bufnr, opts)
  opts = opts or {}
  opts.workspace = true
  return self:format(bufnr, opts)
end

function lang.job(cmd, opts)
  local name = opts.name
  pp(cmd)

  if name then
    local j = lang.jobs[name]
    if j and job.isactive(j) then
      job.close(j)
    end
  end

  opts.stdout = true
  opts.args = opts.args or {}
  opts.stderr = true
  opts.output = true

  --- @diagnostic disable-next-line: param-type-mismatch
  local ok, msg = pcall(job, cmd, opts)

  if not ok then
    tostderr(msg)
    return
  else
    j = msg
  end

  if name then
    lang.jobs[name] = j
  end

  return j
end

function lang:require()
  local config = requirem("core.ft." .. self.name)
  if config then
    return dict.merge(self, config)
  end
end

function lang:loadfile()
  local config = req2path("core.ft." .. self.name)
  if config then
    local ok, msg = pcall(loadfile, config)
    if ok then
      if istable(msg) then
        return dict.merge(self, msg())
      else
        return false
      end
    else
      return false, msg
    end
  end
end

function lang:map(mode, ks, callback, opts)
  opts = opts or {}
  opts.event = "FileType"
  opts.pattern = self.name

  return kbd.map(mode, ks, callback, opts)
end

function lang:au(callback, opts)
  opts = opts or {}
  opts.pattern = self.name
  opts.callback = callback

  return au.map("FileType", opts)
end

function lang:action(bufnr, action, opts)
  if not buffer.exists(bufnr) then
    return
  end

  action = action or "compile"
  local config = self[action]
  opts = opts or {}
  local ws = opts.workspace
  local isdir = opts.dir

  if not config then
    return
  end

  local cmd = self:command(bufnr, action)
  local target

  if (ws and not cmd.workspace) or (isdir and not cmd.dir) then
    return false
  elseif ws then
    cmd, target = unpack(cmd.workspace)
    if cmd:match "%%path" then
      cmd = cmd:gsub("%%path", target)
    else
      cmd = cmd .. " " .. target
    end
  elseif isdir then
    cmd, target = unpack(cmd.dir)
    if cmd:match "%%path" then
      cmd = cmd:gsub("%%path", target)
    else
      cmd = cmd .. " " .. target
    end
  else
    cmd, target = unpack(cmd.buffer)
    if cmd:match "%%path" then
      cmd = cmd:gsub("%%path", target)
    else
      cmd = cmd .. " " .. target
    end
  end

  return lang.job(cmd, {
    before = function()
      buffer.save(bufnr)
    end,
    on_exit = function(x)
      local err = x.errors or {}
      local lines = x.lines or {}

      if x.exit_code ~= 0 then
        list.extend(err, lines)
        tostderr(concat(err, "\n"))

        return
      else
        list.extend(lines, err)
      end

      if #lines == 0 then
        return
      end

      local outbuf = buffer.create()
      buffer.au(outbuf, "WinClosed", function()
        buffer.wipeout(outbuf)
      end)
      buffer.map(outbuf, "n", "q", function()
        buffer.wipeout(outbuf)
      end, { desc = "wipeout buffer" })
      buffer.set_lines(outbuf, 0, -1, lines)
      buffer.botright(outbuf)
    end,
  })
end

function lang:setup_triggers()
  if self.on then
    vim.filetype.add(self.on)
    return true
  end
end

function lang:setup(should_loadfile)
  if should_loadfile then
    self:loadfile()
  else
    self:require()
  end

  self:set_mappings()
  self:setup_triggers()
  self:set_autocmds()

  self:map("n", "<leader>ct", function()
    self:action(buffer.bufnr(), "test", { workspace = true })
  end, { desc = "test buffer" })

  self:map("n", "<leader>ct", function()
    self:action(buffer.bufnr(), "test")
  end, { desc = "test workspace" })

  self:map("n", "<leader>cb", function()
    self:action(buffer.bufnr(), "build", { workspace = true })
  end, { desc = "build buffer" })

  self:map("n", "<leader>cB", function()
    self:action(buffer.bufnr(), "build")
  end, { desc = "build workspace" })

  self:map("n", "<leader>cC", function()
    self:action(buffer.bufnr(), "compile", { workspace = true })
  end, { desc = "compile workspace" })

  self:map("n", "<leader>cc", function()
    self:action(buffer.bufnr(), "compile")
  end, { desc = "compile buffer" })
end

function lang.list()
  local builtin_path = path.join(vim.fn.stdpath "config", "lua", "core", "ft")
  local user_path = path.join(os.getenv "HOME", ".nvim", "lua", "user", "ft")
  local builtin = dir.getallfiles(builtin_path)
  local userconfig = path.isdir(user_path) and dir.getallfiles(user_path) or {}
  builtin = list.filter(builtin, function(x)
    return x:match "%.lua$"
  end)
  userconfig = list.filter(userconfig, function(x)
    return x:match "%.lua$"
  end)

  return list.map(list.union(builtin, userconfig), function(x)
    return (path.basename(x):gsub("%.lua$", ""))
  end)
end

function lang.setup_lsp_all()
  local configured = lang.list()
  list.each(configured, function(x)
    lang(x):setup_lsp()
  end)
end

function lang.main(use_loadfile)
  local configured = lang.list()
  list.each(configured, function(x)
    local obj = lang(x)
    obj:setup(use_loadfile)
  end)
end

function lang:set_autocmds()
  if not (self.autocmds and size(self.autocmds) > 0) then
    return
  end

  dict.each(self.autocmds, function(name, opts)
    assertisa(opts, union("function", "table"))

    local cb, options
    if istable(opts) then
      cb, options = unpack(opts)
    else
      cb = opts
    end

    self:au(cb, options)
  end)
end

function lang:set_mappings()
  if not (self.mappings and size(self.mappings) > 0) then
    return
  end

  dict.each(self.mappings, function(name, spec)
    assertisa(opts, "table")

    specs[4] = specs[4] or {}
    specs[4].name = name

    self:map(unpack(spec))
  end)
end

