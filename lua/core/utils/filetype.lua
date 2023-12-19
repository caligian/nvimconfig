require "core.utils.au"
require "core.utils.buffer"
require "core.utils.win"
require "core.utils.kbd"
require "core.utils.job"

--- @alias filetype.commandspec string|table|fun(path:string): string
--- @alias filetype.mapping table<string,list>
--- @alias filetype.autocmd table<string,fun(table)>

--- @class filetype
--- @field filetypes table<string,filetype>
--- @field on table see `:help vim.filetype`
--- @field linters string|string[]|filetype.linters[] or a combination of any
--- @field server filetype.server
--- @field formatter filetype.formatter
--- @field compile filetype.command
--- @field build filetype.command
--- @field test filetype.command
--- @field mappings filetype.mapping
--- @field autocmds filetype.autocmd
--- @field bo table<string,any> buffer options
--- @field wo table<string,any> window options
--- @field repl table
--- @field jobs table<string,job> jobs for this filetype
--- @field lsp table<string,function> lsp utils
--- @overload fun(string): filetype

--- @class filetype.command
--- @field buffer filetype.commandspec
--- @field workspace filetype.commandspec
--- @field dir filetype.commandspec

--- @class filetype.formatter : filetype.command
--- @field stdin boolean
--- @field append_filename boolean

--- @class filetype.repl : filetype.command
--- @field on_input fun(lines:string[]): string[]
--- @field loadfile fun(path:string, mkfile:fun(p: string))

--- @class filetype.linters
--- @field config table linter config

--- @class filetype.server
--- @field config table lsp server config

filetype = filetype or class "filetype"
filetype = filetype or class "filetype"
filetype.filetypes = filetype.filetypes or {}
filetype.jobs = filetype.jobs or {}
filetype.lsp = module()

--- @class lsp
--- @field diagnostic table<string,any> diagnostic config for vim.lsp
--- @field mappings table
local lsp = filetype.lsp
lsp.diagnostic = {
  virtual_text = false,
  underline = false,
  update_in_insert = false,
}
vim.lsp.handlers["textDocument/hover"] =
  vim.lsp.with(vim.lsp.handlers.hover, {
    border = "single",
    title = "hover",
  })

vim.diagnostic.config(lsp.diagnostic)

lsp.mappings = lsp.mappings
  or {
    float_diagnostic = {
      "n",
      "<leader>li",
      partial(
        vim.diagnostic.open_float,
        { scope = "l", focus = false }
      ),
      {
        desc = "LSP diagnostic float",
        noremap = true,
      },
    },
    set_loclist = {
      "n",
      "lq",
      vim.diagnostic.setloclist,
      {
        desc = "LSP set loclist",
        noremap = true,
        leader = true,
      },
    },
    buffer_declarations = {
      "n",
      "gD",
      vim.lsp.buf.declaration,
      {
        desc = "Buffer declarations",
        silent = true,
        noremap = true,
      },
    },
    buffer_definitions = {
      "n",
      "gd",
      vim.lsp.buf.definition,
      {
        desc = "Buffer definitions",
        silent = true,
        noremap = true,
      },
    },
    float_documentation = {
      "n",
      "K",
      vim.lsp.buf.hover,
      {
        desc = "Show float UI",
        silent = true,
        noremap = true,
      },
    },
    implementations = {
      "n",
      "gi",
      vim.lsp.buf.implementation,
      {
        desc = "Show implementations",
        silent = true,
        noremap = true,
      },
    },
    signatures = {
      "n",
      "<C-k>",
      vim.lsp.buf.signature_help,
      {
        desc = "Signatures",
        silent = true,
        noremap = true,
      },
    },
    add_workspace_folder = {
      "n",
      "<leader>lwa",
      vim.lsp.buf.add_workspace_folder,
      {
        desc = "Add workspace folder",
        silent = true,
        noremap = true,
      },
    },
    remove_workspace_folder = {
      "n",
      "<leader>lwx",
      vim.lsp.buf.remove_workspace_folder,
      {
        desc = "Remove workspace folder",
        silent = true,
        noremap = true,
      },
    },
    list_workspace_folders = {
      "n",
      "<leader>lwl",
      function()
        print(
          vim.inspect(vim.lsp.buf.list_workspace_folders())
        )
      end,
      {
        desc = "List workspace folders",
        silent = true,
        noremap = true,
      },
    },
    type_definition = {
      "n",
      "<leader>lD",
      vim.lsp.buf.type_definition,
      {
        desc = "Show type definitions",
        silent = true,
        noremap = true,
      },
    },
    buffer_rename = {
      "n",
      "<leader>lR",
      vim.lsp.buf.rename,
      {
        desc = "Rename buffer",
        silent = true,
        noremap = true,
      },
    },
    code_action = {
      "n",
      "<leader>la",
      vim.lsp.buf.code_action,
      {
        desc = "Show code actions",
        silent = true,
        noremap = true,
      },
    },
    buffer_references = {
      "n",
      "gr",
      vim.lsp.buf.references,
      {
        desc = "Show buffer references",
        silent = true,
        noremap = true,
      },
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
    buffer.set_option(
      bufnr,
      "omnifunc",
      "v:lua.vim.lsp.omnifunc"
    )

    local ft = vim.bo.filetype
    local has_formatter = filetype(ft)
    if has_formatter and not has_formatter.formatter then
      lsp.attach_formatter(client)
    end

    local mappings = deepcopy(lsp.mappings)
    for _, value in pairs(mappings) do
      value[4] = value[4] or {}
      value[4].buffer = bufnr
    end

    kbd.fromdict(mappings)
  end
end

function lsp.setup_server(server, opts)
  opts = opts or {}
  local capabilities = opts.capabilities
    or require("cmp_nvim_lsp").default_capabilities()
  local on_attach = opts.on_attach or lsp.on_attach
  local flags = opts.flags
  local default_conf = {
    capabilities = capabilities,
    on_attach = on_attach,
    flags = flags,
  }

  default_conf = dict.merge(default_conf, opts)

  if default_conf.cmd then
    default_conf.cmd = tolist(default_conf.cmd)
  end

  require("lspconfig")[server].setup(default_conf)
end

function filetype:isa()
  return typeof(self) == "filetype"
end

function filetype:init(name)
  if filetype.isa(name) then
    return name
  elseif istable(name) then
    assert(name.name, "name is missing in " .. dump(name))
    local l = filetype(name.name)
    dict.merge(l, name)

    filetype.filetypes[name.name] = l
    return l
  elseif isnumber(name) then
    assert(buffer.exists(name), "invalid buffer " .. name)
    return filetype(buffer.filetype(name))
  else
    local l = filetype.filetypes[name]
    if l then
      return l
    end
  end

  self.name = name
  filetype.filetypes[name] = self

  return self
end

function filetype:setbo(bo)
  bo = bo or self.bo
  if not bo or size(bo) == 0 then
    return
  end

  self:au(function(opts)
    buffer.set_option(opts.buf, bo)
  end)
end

function filetype:setwo(wo)
  wo = wo or self.wo
  if not wo or size(wo) == 0 then
    return
  end

  asserttype(wo, "table")

  self:au(function(opts)
    local winnr = buffer.winnr(opts.buf)
    if winnr then
      win.set_option(winnr, wo)
    end
  end)
end

local function capitalize(name)
  local first = substr(name, 1, 1)
  return first:upper() .. substr(name, 2, -1)
end

function filetype:vimcommand(name, callback, opts)
  opts = opts or {}
  local createcmd = vim.api.nvim_buf_create_user_command
  name = "Filetype"
    .. capitalize(self.name)
    .. capitalize(name)

  return self:au(function(bufopts)
    createcmd(bufopts.buf, name, callback, opts)
  end, opts)
end

--- @param specs? string|{ [1]: string, config: table }
function filetype:setup_lsp(specs)
  specs = specs or self.server
  specs = isstring(specs) and { specs } --[[@as table]]
    or specs

  if not specs then
    return
  end

  lsp.setup_server(specs[1], specs.config)

  return self
end

local function find_workspace(
  start_dir,
  pats,
  maxdepth,
  _depth
)
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

function filetype:query(attrib, f)
  self = filetype(self)

  if self[attrib] then
    return f and f(self[attrib]) or self[attrib]
  end
end

function filetype.workspace(bufnr, pats, maxdepth, _depth)
  bufnr = bufnr or buffer.bufnr()
  if isstring(bufnr) then
    bufnr = buffer.bufnr(bufnr)
  end

  if not buffer.exists(bufnr) then
    return false
  end

  local lspconfig = require "lspconfig"
  ---@diagnostic disable-next-line: param-type-mismatch
  local server =
    filetype.query(buffer.filetype(bufnr), "server")

  local bufname = buffer.name(bufnr)

  if server then
    server = tolist(server)

    local config = isstring(server) and lspconfig[server]
      or lspconfig[server[1]]

    local root_dir_checker = server.get_root_dir
      or config.document_config.default_config.root_dir
      or config.get_root_dir

    if root_dir_checker then
      return root_dir_checker(bufname)
    else
      return find_workspace(bufname, pats, maxdepth, _depth)
    end
  else
    return find_workspace(bufname, pats, maxdepth, _depth)
  end
end

function filetype:command(bufnr, action)
  action = action or "compile"
  local validactions =
    { "compile", "build", "test", "repl", "formatter" }

  params {
    buffer = { "number", bufnr },
    action = {
      function(x)
        return list.contains(validactions, x)
      end,
      action,
    },
  }

  assert(
    buffer.exists(bufnr),
    "invalid buffer: " .. dump(bufnr)
  )

  local bufname = buffer.name(bufnr)
  local compile = self[action]
  local spec = union("string", "table", "function")

  if not compile then
    return
  else
    assert(isa[spec](compile))
  end

  local opts = dict.filter(compile, function(key, _)
    return key ~= "buffer"
      and key ~= "workspace"
      and key ~= "dir"
  end)

  if not istable(compile) then
    compile = dict.merge({ buffer = spec }, opts)
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
    elseif isstring(X[1]) then
      X = copy(X)
      local cmd = X[1]
      X[1] = nil

      return cmd, X
    else
      local out = getfromtable(X, what)
      return dwim(out, what)
    end
  end

  local out = {}
  local function withpath(cmd, p)
    if istemplate(cmd) then
      local templ = template(cmd)
      cmd = templ { assert = true, path = p }
    end

    return { cmd, p }
  end

  if compile[1] or compile.buffer then
    local cmd, _opts =
      dwim(compile[1] or compile.buffer, bufname)
    _opts = _opts or {}

    dict.lmerge(_opts, opts)

    if cmd then
      out.buffer = withpath(cmd, bufname)
    end
  end

  if compile.dir then
    local d = path.dirname(bufname)
    local cmd, _opts = dwim(compile.dir, d)
    _opts = _opts or {}

    dict.lmerge(_opts, opts)

    if cmd then
      out.dir = withpath(cmd, d)
    end
  end

  if compile.workspace then
    local ws = filetype.workspace(bufnr)
    if ws then
      local cmd, _opts = dwim(compile.workspace, ws)
      _opts = _opts or {}

      dict.lmerge(_opts, opts)

      if cmd then
        out.workspace = withpath(cmd, ws)
      end
    end
  end

  if size(out) == 0 then
    error(
      self.name .. "." .. action .. ": no commands exist"
    )
  end

  return out, opts
end

function filetype:format(bufnr, opts)
  opts = opts or {}
  local cmd, _opts = self:command(bufnr, "formatter")
  local target
  opts = dict.lmerge(copy(opts), _opts)
  local stdin = opts.stdin
  local bufname = buffer.name(bufnr)
  local name

  if opts.dir then
    name = "filetype.formatter.dir."
  elseif opts.workspace then
    name = "filetype.formatter.workspace."
  else
    name = "filetype.formatter.buffer."
  end

  if opts.workspace then
    cmd, target = unpack(cmd.workspace)
  elseif opts.buffer then
    cmd, target = unpack(cmd.buffer)
    if opts.stdin then
      cmd = sprintf('sh -c "cat %s | %s"', target, cmd)
    end
  elseif opts.dir then
    cmd, target = unpack(cmd.dir)
  end

  target = target or bufname
  name = name .. target
  assert(
    cmd,
    "filetype."
      .. self.name
      .. ".formatter"
      .. ": no command exists"
  )

  local function createcmd(tp)
    if tp == "buffer" then
      if append_filename == nil and stdin == nil then
        stdin = true
      end
    end

    return cmd, target
  end

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

  local proc = filetype.job(cmd, {
    name = name,
    cwd = (opts.workspace or opts.dir) and target
      or path.dirname(bufname),
    before = function()
      vim.cmd(":w! " .. bufname)
      buffer.set_option(bufnr, "modifiable", false)
    end,
    on_exit = function(x)
      if x.exit_code ~= 0 then
        buffer.set_option(bufnr, "modifiable", true)

        local err = #x.errors > 1 and x.errors
          or #x.lines > 1 and x.lines
        if err then
          ---@diagnostic disable-next-line: cast-local-type
          err = join(err, "\n")
          tostderr(err)
        else
          print(
            "check source syntax for buffer " .. bufname
          )
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

function filetype:format_dir(bufnr, opts)
  opts = opts or {}
  opts.dir = true
  return self:format(bufnr, opts)
end

function filetype:format_workspace(bufnr, opts)
  opts = opts or {}
  opts.workspace = true
  return self:format(bufnr, opts)
end

function filetype.job(cmd, opts)
  local name = opts.name

  if name then
    local j = filetype.jobs[name]
    if j and job.is_active(j) then
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
    filetype.jobs[name] = j
  end

  return j
end

function filetype:require()
  local config = requirem("core.filetype." .. self.name)
  if config then
    return dict.merge(self, config)
  end
end

function filetype:loadfile()
  local config = req2path("core.filetype." .. self.name)
  if config then
    local ok, msg = pcall(loadfile, config)
    if ok then
      msg = msg()
      if istable(msg) then
        return dict.merge(self, msg)
      else
        return false
      end
    else
      return false, msg
    end
  end
end

function filetype:map(mode, ks, callback, opts)
  opts = opts or {}
  opts.event = "FileType"
  opts.pattern = self.name

  return kbd.map(mode, ks, callback, opts)
end

function filetype:au(callback, opts)
  opts = opts or {}
  opts.pattern = self.name
  opts.callback = callback

  return au.map("FileType", opts)
end

function filetype:action(bufnr, action, opts)
  if not buffer.exists(bufnr) then
    return
  end

  action = action or "compile"
  local config = self[action]
  opts = opts or {}
  local ws = opts.workspace
  local isdir = opts.dir
  local tp = opts.workspace and "workspace"
    or opts.dir and "dir"
    or "buffer"

  if not config then
    return
  end

  local name = "filetype." .. action .. "." .. tp .. "."
  local cmd = self:command(bufnr, action)

  if not cmd then
    return
  end

  local target

  if
    (ws and not cmd.workspace) or (isdir and not cmd.dir)
  then
    return
  elseif ws then
    cmd, target = unpack(cmd.workspace)
  elseif isdir then
    cmd, target = unpack(cmd.dir)
  else
    cmd, target = unpack(cmd.buffer)
  end

  name = name .. target
  return filetype.job(cmd, {
    name = name,
    cwd = isdir or ws and target,
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

function filetype:setup_triggers()
  if self.on then
    vim.filetype.add(self.on)
    return true
  end
end

function filetype:setup(should_loadfile)
  if should_loadfile then
    self:loadfile()
  else
    self:require()
  end

  self:setup_triggers()
  self:set_mappings()
  self:set_autocmds()
  self:setbo()
  self:setwo()

  self:map("n", "<leader>ct", function()
    self:action(
      buffer.bufnr(),
      "test",
      { workspace = true }
    )
  end, { desc = "test buffer" })

  self:map("n", "<leader>ct", function()
    self:action(buffer.bufnr(), "test")
  end, { desc = "test workspace" })

  self:map("n", "<leader>cb", function()
    self:action(
      buffer.bufnr(),
      "build",
      { workspace = true }
    )
  end, { desc = "build buffer" })

  self:map("n", "<leader>cB", function()
    self:action(buffer.bufnr(), "build")
  end, { desc = "build workspace" })

  self:map("n", "<leader>cC", function()
    self:action(
      buffer.bufnr(),
      "compile",
      { workspace = true }
    )
  end, { desc = "compile workspace" })

  self:map("n", "<leader>cc", function()
    self:action(buffer.bufnr(), "compile")
  end, { desc = "compile buffer" })

  return self
end

function filetype.list()
  local builtin_path = path.join(
    vim.fn.stdpath "config",
    "lua",
    "core",
    "filetype"
  )
  local user_path = path.join(
    os.getenv "HOME",
    ".nvim",
    "lua",
    "user",
    "filetype"
  )
  local builtin = dir.getallfiles(builtin_path)
  local userconfig = path.isdir(user_path)
      and dir.getallfiles(user_path)
    or {}
  builtin = list.filter(builtin, function(x)
    return x:match "%.lua$"
  end)
  userconfig = list.filter(userconfig, function(x)
    return x:match "%.lua$"
  end)

  return list.map(
    list.union(builtin, userconfig),
    function(x)
      return (path.basename(x):gsub("%.lua$", ""))
    end
  )
end

function filetype.setup_lsp_all()
  local configured = filetype.list()
  list.each(configured, function(x)
    filetype(x):setup_lsp()
  end)
end

function filetype:set_autocmds()
  if not (self.autocmds and size(self.autocmds) > 0) then
    return
  end

  dict.each(self.autocmds, function(name, opts)
    assertisa(opts, union("function", "table"))

    local cb, options
    options = {}
    if istable(opts) then
      cb, options = unpack(opts)
    else
      cb = opts
    end

    options.name = name
    self:au(cb, options)
  end)
end

function filetype:set_mappings()
  if not (self.mappings and size(self.mappings) > 0) then
    return
  end

  local opts = self.mappings.opts or {}
  local mode = opts.mode or "n"

  dict.each(self.mappings, function(name, spec)
    if name == "opts" then
      return
    end

    assert(#spec >= 3, "expected at least 3 arguments")

    if #spec ~= 4 then
      list.lappend(spec, mode)
    end

    spec[4] = spec[4] or {}
    spec[4] = isstring(spec[4]) and { desc = spec[4] }
      or spec[4]
    spec[4].name = name

    dict.merge(spec[4], opts)

    self:map(unpack(spec))
  end)
end

function filetype.main(use_loadfile)
  local configured = filetype.list()

  list.each(configured, function(x)
    local obj = filetype(x)
    obj:setup(use_loadfile)
  end)

  kbd.map("n", "<leader>mb", function()
    local buf = buffer.current()
    filetype(buf):action(buf, "build", { workspace = true })
  end, "build workspace")

  kbd.map("n", "<leader>cb", function()
    local buf = buffer.current()
    filetype(buf):action(buf, "build", { buffer = true })
  end, "build buffer")

  kbd.map("n", "<leader>cB", function()
    local buf = buffer.current()
    filetype(buf)
      :require()
      :action(buf, "build", { dir = true })
  end, "build dir")

  kbd.map("n", "<leader>mt", function()
    local buf = buffer.current()
    filetype(buf)
      :require()
      :action(buf, "test", { workspace = true })
  end, "test workspace")

  kbd.map("n", "<leader>ct", function()
    local buf = buffer.current()
    filetype(buf)
      :require()
      :action(buf, "test", { buffer = true })
  end, "test buffer")

  kbd.map("n", "<leader>cT", function()
    local buf = buffer.current()
    filetype(buf)
      :require()
      :action(buf, "test", { dir = true })
  end, "test dir")

  kbd.map("n", "<leader>mc", function()
    local buf = buffer.current()
    filetype(buf)
      :require()
      :action(buf, "compile", { workspace = true })
  end, "compile workspace")

  kbd.map("n", "<leader>cc", function()
    local buf = buffer.current()
    filetype(buf)
      :require()
      :action(buf, "compile", { buffer = true })
  end, "compile buffer")

  kbd.map("n", "<leader>cC", function()
    local buf = buffer.current()
    filetype(buf)
      :require()
      :action(buf, "compile", { dir = true })
  end, "compile dir")

  kbd.map("n", "<leader>mf", function()
    local buf = buffer.current()
    filetype(buf):format_workspace(buf)
  end, "format workspace")

  kbd.map("n", "<leader>bf", function()
    local buf = buffer.current()
    filetype(buf):format(buf, { buffer = true })
  end, "format buffer")

  kbd.map("n", "<leader>bF", function()
    local buf = buffer.current()
    filetype(buf):format_dir(buf)
  end, "format dir")
end
