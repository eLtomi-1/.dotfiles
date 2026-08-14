--[[
=====================================================================
==================== KICKSTART.NVIM — TOMI's FORK ===================
=====================================================================
Based on nvim-lua/kickstart.nvim @ master (vim.pack era).
Personal customizations isolated under lua/custom/ so future upstream
syncs stay easy.

Layout:
  init.lua                    — upstream base + small inline overrides
  lua/custom/init.lua         — personal keymaps, autocmds, DAP wiring
  lua/custom/plugins/init.lua — personal plugin specs (vim.pack style)
  lua/kickstart/plugins/*.lua — upstream optional modules

Requires Neovim >= 0.12 (vim.pack).
--]]

-- ============================================================
-- SECTION 1: FOUNDATION
-- Core Neovim settings, leaders, options, basic keymaps, basic autocmds
-- ============================================================
do
  -- Enable faster startup by caching compiled Lua modules
  vim.loader.enable()

  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '

  -- Nerd Font is installed
  vim.g.have_nerd_font = true

  -- ---- Performance: disable unused providers ----
  vim.g.loaded_python3_provider = 0
  vim.g.loaded_node_provider = 0
  vim.g.loaded_perl_provider = 0
  vim.g.loaded_ruby_provider = 0

  -- ---- Performance: disable unused built-in plugins ----
  local disabled_builtins = {
    'gzip',
    'tarPlugin',
    'zipPlugin',
    'tutor',
    'rplugin',
    'matchparen', -- treesitter / mini.ai handle it
    'netrwPlugin', -- replaced by oil.nvim
    'spellfile_plugin',
  }
  for _, p in ipairs(disabled_builtins) do
    vim.g['loaded_' .. p] = 1
  end

  -- [[ Setting options ]]
  vim.o.number = true
  vim.o.relativenumber = true -- personal override
  vim.o.mouse = 'a'
  vim.o.showmode = false
  vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)
  vim.o.breakindent = true
  vim.o.undofile = true
  vim.o.ignorecase = true
  vim.o.smartcase = true
  vim.o.signcolumn = 'yes'
  vim.o.updatetime = 250
  vim.o.timeoutlen = 300
  vim.o.splitright = true
  vim.o.splitbelow = true
  vim.o.list = true
  vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
  vim.o.inccommand = 'split'
  vim.o.cursorline = false -- personal override
  vim.o.guicursor = '' -- personal override (block cursor in all modes)
  vim.o.swapfile = false -- personal override
  vim.o.scrolloff = 10
  vim.o.confirm = true

  -- [[ Basic Keymaps ]]
  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

  -- Diagnostic Config
  vim.diagnostic.config {
    update_in_insert = false,
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    underline = { severity = { min = vim.diagnostic.severity.WARN } },
    virtual_text = true,
    virtual_lines = false,
    jump = {
      on_jump = function(_, bufnr) vim.diagnostic.open_float { bufnr = bufnr, scope = 'cursor', focus = false } end,
    },
  }

  -- NOTE: upstream binds <leader>q to vim.diagnostic.setloclist.
  -- Personal override: <leader>q is rebound to Snacks.picker.grep() in lua/custom/init.lua.

  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

  -- Window navigation
  vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus left' })
  vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus right' })
  vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus down' })
  vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus up' })

  -- Highlight on yank
  vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight on yank',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function() vim.hl.on_yank() end,
  })

  -- ---- Performance: big-file guard ----
  vim.api.nvim_create_autocmd('BufReadPre', {
    group = vim.api.nvim_create_augroup('bigfile-guard', { clear = true }),
    callback = function(ev)
      local ok, stats = pcall(vim.loop.fs_stat, ev.match)
      if ok and stats and stats.size > 1.5 * 1024 * 1024 then
        vim.b[ev.buf].large_buf = true
        vim.opt_local.syntax = ''
        vim.opt_local.foldmethod = 'manual'
        vim.opt_local.spell = false
        pcall(vim.treesitter.stop, ev.buf)
      end
    end,
  })
end

-- ============================================================
-- SECTION 2: PLUGIN MANAGER INTRO
-- vim.pack intro, build hooks
-- ============================================================
do
  local function run_build(name, cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd }):wait()
    if result.code ~= 0 then
      local stderr = result.stderr or ''
      local stdout = result.stdout or ''
      local output = stderr ~= '' and stderr or stdout
      if output == '' then output = 'No output from build command.' end
      vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
    end
  end

  -- pcall: tolerate older nvim builds where PackChanged isn't registered yet
  pcall(vim.api.nvim_create_autocmd, 'PackChanged', {
    callback = function(ev)
      local name = ev.data.spec.name
      local kind = ev.data.kind
      if kind ~= 'install' and kind ~= 'update' then return end

      if name == 'LuaSnip' then
        if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then run_build(name, { 'make', 'install_jsregexp' }, ev.data.path) end
        return
      end

      if name == 'nvim-treesitter' then
        if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
        vim.cmd 'TSUpdate'
        return
      end
    end,
  })
end

local function gh(repo) return 'https://github.com/' .. repo end

-- ============================================================
-- SECTION 3: UI / CORE UX PLUGINS
-- guess-indent, gitsigns, which-key, colorscheme, todo-comments, mini modules
-- ============================================================
do
  vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
  require('guess-indent').setup {}

  if vim.g.have_nerd_font then vim.pack.add { gh 'nvim-tree/nvim-web-devicons' } end

  vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
  require('gitsigns').setup {
    signs = {
      add = { text = '+' }, ---@diagnostic disable-line: missing-fields
      change = { text = '~' }, ---@diagnostic disable-line: missing-fields
      delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
      topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
      changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
    },
  }

 -- vim.pack.add { gh 'folke/which-key.nvim' }
-- require('which-key').setup {
--   delay = 0,
--   icons = { mappings = vim.g.have_nerd_font },
--   spec = {
--     { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
--     { '<leader>t', group = '[T]oggle' },
--     { '<leader>z', group = '[Z]uzu build' },
--     { '<leader>c', group = '[C]ode' },
--     { 'gr', group = 'LSP Actions', mode = { 'n' } },
--   },
-- }

  vim.pack.add { gh 'folke/tokyonight.nvim' }
  ---@diagnostic disable-next-line: missing-fields
  require('tokyonight').setup {
    styles = { comments = { italic = false } },
    on_highlights = function(hl, _)
      -- Personal: transparent background
      hl.Normal = { bg = 'NONE' }
      hl.NormalNC = { bg = 'NONE' }
      hl.SignColumn = { bg = 'NONE' }
      hl.EndOfBuffer = { bg = 'NONE' }
    end,
  }
  vim.cmd.colorscheme 'tokyonight-night'

  vim.pack.add { gh 'folke/todo-comments.nvim' }
  require('todo-comments').setup { signs = false }

  vim.pack.add { gh 'nvim-mini/mini.nvim' }
  require('mini.ai').setup {
    mappings = { around_next = 'aa', inside_next = 'ii' },
    n_lines = 500,
  }
  require('mini.surround').setup()
  local statusline = require 'mini.statusline'
  statusline.setup { use_icons = vim.g.have_nerd_font }
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_location = function() return '%2l:%-2v' end
end

-- ============================================================
-- SECTION 4: (REMOVED) SEARCH & NAVIGATION
-- Telescope is replaced by snacks.picker.
-- Picker plugin spec lives in lua/custom/plugins/init.lua.
-- All <leader>s* keymaps + LspAttach picker mappings live in lua/custom/init.lua.
-- ============================================================

-- ============================================================
-- SECTION 5: LSP
-- LSP keymaps, server configuration, Mason tools installations
-- ============================================================
do
  vim.pack.add { gh 'j-hui/fidget.nvim' }
  require('fidget').setup {}

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
    callback = function(event)
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end

      map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
      map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
      map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client:supports_method('textDocument/documentHighlight', event.buf) then
        local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })
        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
          end,
        })
      end

      if client and client:supports_method('textDocument/inlayHint', event.buf) then
        map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
      end
    end,
  })

  ---@type table<string, vim.lsp.Config>
  local servers = {
    clangd = {
      cmd = {
        'clangd',
        '--background-index',
        '--clang-tidy',
        '--header-insertion=iwyu',
        '--completion-style=detailed',
        '--function-arg-placeholders',
        '--fallback-style=llvm',
      },
      init_options = {
        usePlaceholders = true,
        completeUnimported = true,
        clangdFileStatus = true,
      },
    },
    gopls = {},
    lua_ls = {
      on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false
        if client.workspace_folders then
          local path = client.workspace_folders[1].name
          if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
        end
        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
          runtime = { version = 'LuaJIT', path = { 'lua/?.lua', 'lua/?/init.lua' } },
          workspace = {
            checkThirdParty = false,
            library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
              '${3rd}/luv/library',
              '${3rd}/busted/library',
            }),
          },
        })
      end,
      ---@type lspconfig.settings.lua_ls
      settings = {
        Lua = { format = { enable = false } },
      },
    },
  }

  vim.pack.add {
    gh 'neovim/nvim-lspconfig',
    gh 'mason-org/mason.nvim',
    gh 'mason-org/mason-lspconfig.nvim',
    gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
  }
  require('mason').setup {}

  -- LSP servers go through vim.lsp.enable. Non-LSP tools listed separately
  -- so mason-tool-installer can fetch them.
  local extra_tools = { 'stylua', 'clang-format', 'codelldb' }
  local ensure_installed = vim.tbl_keys(servers)
  vim.list_extend(ensure_installed, extra_tools)
  require('mason-tool-installer').setup { ensure_installed = ensure_installed }

  for name, server in pairs(servers) do
    vim.lsp.config(name, server)
    vim.lsp.enable(name)
  end
end

-- ============================================================
-- SECTION 6: FORMATTING
-- conform.nvim setup (format-on-save OFF per user choice)
-- ============================================================
do
  vim.pack.add { gh 'stevearc/conform.nvim' }
  require('conform').setup {
    notify_on_error = false,
    -- Format-on-save disabled. To enable later:
    --   format_on_save = { lsp_format = 'fallback', timeout_ms = 500 },
    format_on_save = nil,
    default_format_opts = { lsp_format = 'fallback' },
    formatters_by_ft = {
      c = { 'clang_format' },
      cpp = { 'clang_format' },
      cuda = { 'clang_format' },
    },
  }

  -- Personal: format via <leader>cf (upstream <leader>f is taken by todo picker)
  vim.keymap.set({ 'n', 'v' }, '<leader>cf', function() require('conform').format { async = true } end, { desc = '[C]ode [F]ormat buffer' })
end

-- ============================================================
-- SECTION 7: AUTOCOMPLETE & SNIPPETS
-- blink.cmp and luasnip setup
-- ============================================================
do
  vim.pack.add { { src = gh 'L3MON4D3/LuaSnip', version = vim.version.range '2.*' } }
  require('luasnip').setup {}

  vim.pack.add { gh 'rafamadriz/friendly-snippets' }
  require('luasnip.loaders.from_vscode').lazy_load()

  vim.pack.add { { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }
  require('blink.cmp').setup {
    keymap = { preset = 'default' },
    appearance = { nerd_font_variant = 'mono' },
    completion = {
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
    },
    sources = { default = { 'lsp', 'path', 'snippets' } },
    snippets = { preset = 'luasnip' },
    fuzzy = { implementation = 'lua' },
    signature = { enabled = true },
  }
end

-- ============================================================
-- SECTION 8: TREESITTER
-- Parser installation, syntax highlighting, folds, indentation
-- ============================================================
do
  vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

  local parsers = {
    -- Upstream defaults
    'bash',
    'c',
    'diff',
    'html',
    'lua',
    'luadoc',
    'markdown',
    'markdown_inline',
    'query',
    'vim',
    'vimdoc',
    -- Personal additions (C++ stack + general)
    'cpp',
    'cmake',
    'make',
    'cuda',
    'go',
    'json',
    'yaml',
    'toml',
  }
  require('nvim-treesitter').install(parsers)

  ---@param buf integer
  ---@param language string
  local function treesitter_try_attach(buf, language)
    if not vim.treesitter.language.add(language) then return end
    vim.treesitter.start(buf, language)
    local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil
    if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
  end

  local available_parsers = require('nvim-treesitter').get_available()
  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      local buf, filetype = args.buf, args.match
      local language = vim.treesitter.language.get_lang(filetype)
      if not language then return end
      local installed_parsers = require('nvim-treesitter').get_installed 'parsers'
      if vim.tbl_contains(installed_parsers, language) then
        treesitter_try_attach(buf, language)
      elseif vim.tbl_contains(available_parsers, language) then
        require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
      else
        treesitter_try_attach(buf, language)
      end
    end,
  })
end

-- ============================================================
-- SECTION 9: OPTIONAL KICKSTART MODULES + CUSTOM LAYER
-- ============================================================
do
  require 'kickstart.plugins.autopairs'
  require 'kickstart.plugins.debug' -- DAP framework; codelldb wired in via custom layer
  require 'kickstart.plugins.lint'
  require 'kickstart.plugins.indent_line'
  -- require 'kickstart.plugins.gitsigns'   -- SKIP: hunk keymaps collide with <leader>h (kulala)
  -- require 'kickstart.plugins.neo-tree'   -- SKIP: oil.nvim covers it

  -- Personal layer: keymaps, plugins, autocmds
  require 'custom'
end

-- vim: ts=2 sts=2 sw=2 et
