-- =============================================================
-- Personal customization layer (loaded at the end of init.lua)
-- Keymaps, filetypes, LSP-attach picker mappings, DAP wiring.
-- Personal plugin specs live in lua/custom/plugins/init.lua.
-- =============================================================

local map = vim.keymap.set

-- =============================================================
-- Basic keymaps
-- =============================================================
map('n', '<leader>w', '<cmd>w<cr>', { desc = 'Save' })
map('n', '<leader>g', '<cmd>Neogit<cr>', { desc = 'Neogit' })
-- map('n', '<leader><leader>', '`.', { desc = 'Jump to last edit' })
map('n', '<leader>cm', '<cmd>Mason<cr>', { desc = '[C]ode [M]ason' })
map('n', '<leader>l', '<cmd>lua vim.pack.update()<cr>', { desc = 'Update plugins (vim.pack)' })
map('n', '<leader>s', 'ZZ', { desc = 'Save & quit' })
map('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Diagnostic float' })

-- Motion remaps
map({ 'n', 'v' }, 'H', '0')
map({ 'n', 'v' }, 'L', '$')
map('n', 'q', '/')
map('n', ';', ':')

-- Split shortcuts
map('n', '<tab>', '<cmd>vsplit<cr>', { desc = 'Vertical split' })
map('n', '<tab><tab>', '<cmd>split<cr>', { desc = 'Horizontal split' })

-- Window resize
map('n', '<C-M-h>', '<cmd>vertical resize -5<cr>', { desc = 'Resize left' })
map('n', '<C-M-l>', '<cmd>vertical resize +5<cr>', { desc = 'Resize right' })
map('n', '<C-M-j>', '<cmd>resize -5<cr>', { desc = 'Resize down' })
map('n', '<C-M-k>', '<cmd>resize +5<cr>', { desc = 'Resize up' })

-- =============================================================
-- Picker keymaps (snacks.picker replaces Telescope)
-- These are wrapped in pcall via a small helper so they don't
-- error if snacks fails to load on first run.
-- =============================================================
local function pick(source, opts)
  return function()
    local ok, snacks = pcall(require, 'snacks')
    if not ok or not snacks.picker then
      vim.notify('snacks.picker unavailable', vim.log.levels.WARN)
      return
    end
    if opts then
      snacks.picker[source](opts)
    else
      snacks.picker[source]()
    end
  end
end

-- Personal picker binds (user-wins on collisions with upstream)
map('n', '<leader>j', pick 'files', { desc = 'Find files' })
map('n', '<leader>c', pick 'grep_word', { desc = 'Grep word under cursor' })
map('n', '<leader>q', pick 'grep', { desc = 'Live grep' })
map('n', '<leader>p', pick 'zoxide', { desc = 'Zoxide' })
map('n', '<leader><leader>', pick 'resume', { desc = 'Resume' })
map('n', '<leader>/', pick 'lines', { desc = 'Fuzzy search current buffer' })

-- Upstream-equivalent search namespace (ported Telescope → snacks.picker)
map('n', '<leader>sh', pick 'help', { desc = '[S]earch [H]elp' })
map('n', '<leader>sk', pick 'keymaps', { desc = '[S]earch [K]eymaps' })
map('n', '<leader>sf', pick 'files', { desc = '[S]earch [F]iles' })
map('n', '<leader>sd', pick 'diagnostics', { desc = '[S]earch [D]iagnostics' })
map('n', '<leader>sb', pick 'buffers', { desc = '[S]earch [B]uffers' })
map('n', '<leader>sa', pick 'picker_actions', { desc = '[S]earch [A]ctions' })
map('n', '<leader>sp', pick 'pickers', { desc = '[S]earch [P]ickers' })
map(
  'n',
  '<leader>sn',
  function()
    require('snacks').picker.files { cwd = vim.fn.stdpath 'config' }
  end,
  { desc = '[S]earch [N]eovim config' }
)

-- =============================================================
-- LSP-attach picker mappings (replaces telescope.builtin.lsp_*)
-- =============================================================
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('custom-lsp-picker-attach', { clear = true }),
  callback = function(event)
    local buf = event.buf
    local m = function(keys, source, desc)
      map('n', keys, pick(source), { buffer = buf, desc = 'LSP: ' .. desc })
    end
    m('grr', 'lsp_references', '[G]oto [R]eferences')
    m('gri', 'lsp_implementations', '[G]oto [I]mplementation')
    m('grd', 'lsp_definitions', '[G]oto [D]efinition')
    m('grt', 'lsp_type_definitions', '[G]oto [T]ype Definition')
    m('gO', 'lsp_symbols', 'Document Symbols')
    m('gW', 'lsp_workspace_symbols', 'Workspace Symbols')

    -- References in current file (project-wide refs live on grr)
    map('n', '<leader>f', pick('lsp_references', { filter = { buf = true } }), { buffer = buf, desc = 'LSP: References (current file)' })

    -- Definition: gd opens it in a horizontal split, gD jumps in current window
    map('n', 'gd', pick('lsp_definitions', { confirm = 'edit_split' }), { buffer = buf, desc = 'LSP: Definition (split)' })
    map('n', 'gD', pick 'lsp_definitions', { buffer = buf, desc = 'LSP: Definition' })
  end,
})

-- =============================================================
-- Filetype registrations
-- =============================================================
vim.filetype.add { extension = { http = 'http' } }

-- =============================================================
-- C / C++ filetype-specific keymap
-- =============================================================
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'c', 'cpp' },
  callback = function(ev)
    map('n', '<leader>ch', '<cmd>LspClangdSwitchSourceHeader<cr>', {
      buffer = ev.buf,
      desc = 'C/C++: Switch Header/Source',
    })
  end,
})

-- =============================================================
-- DAP keymaps + codelldb adapter for C / C++
-- (DAP framework loaded by kickstart.plugins.debug)
-- =============================================================
local ok, dap = pcall(require, 'dap')
if ok then
  map('n', '<F5>', function() dap.continue() end, { desc = 'DAP: Continue' })
  map('n', '<F10>', function() dap.step_over() end, { desc = 'DAP: Step Over' })
  map('n', '<F11>', function() dap.step_into() end, { desc = 'DAP: Step Into' })
  map('n', '<F12>', function() dap.step_out() end, { desc = 'DAP: Step Out' })
  -- <leader>b is already bound to dap.toggle_breakpoint by kickstart.plugins.debug

  dap.adapters.codelldb = {
    type = 'server',
    port = '${port}',
    executable = {
      command = vim.fn.exepath 'codelldb',
      args = { '--port', '${port}' },
    },
  }
  for _, lang in ipairs { 'c', 'cpp' } do
    dap.configurations[lang] = {
      {
        name = 'Launch file',
        type = 'codelldb',
        request = 'launch',
        program = function() return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file') end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
      },
    }
  end
end

-- =============================================================
-- Load personal plugin specs
-- =============================================================
require 'custom.plugins'
