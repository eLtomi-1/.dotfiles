-- =============================================================
-- Personal plugin specs (vim.pack idiom)
-- Loaded by lua/custom/init.lua at the end of init.lua boot.
--
-- ALL installs happen in ONE vim.pack.add call up top so they
-- complete (synchronously, blocking) before any setup() runs.
-- This avoids first-boot "module 'X' not found" races.
-- =============================================================

local function gh(repo) return 'https://github.com/' .. repo end

-- -------------------------------------------------------------
-- 1. Install everything up front (one batch — single blocking call)
-- -------------------------------------------------------------
vim.pack.add {
  gh 'max397574/better-escape.nvim',
  { src = 'https://codeberg.org/andyg/leap.nvim' },
  gh 'NeogitOrg/neogit',
  gh 'nvim-lua/plenary.nvim',
  gh 'sindrets/diffview.nvim',
  gh 'stevearc/oil.nvim',
  gh 'ThePrimeagen/harpoon',  -- v1 (master branch)
  -- gh 'LeonHeidelbach/trailblazer.nvim',  -- dropped: marks were position-based, wanted file-based
  gh 'mistweaverco/kulala.nvim',
  gh 'p00f/clangd_extensions.nvim',
  gh 'Civitasv/cmake-tools.nvim',
  gh 'gitpushjoe/zuzu.nvim',
  gh 'folke/snacks.nvim',
}

-- -------------------------------------------------------------
-- Helper: setup with pcall — if a plugin failed to clone or its
-- module API changed, log and continue rather than crashing init.
-- -------------------------------------------------------------
local function safe_setup(name, fn)
  local ok, err = pcall(fn)
  if not ok then vim.notify(('[%s] setup failed: %s'):format(name, err), vim.log.levels.WARN) end
end

-- -------------------------------------------------------------
-- 2. better-escape.nvim  —  jk / JK to escape
--    (module name is `better_escape` with underscore)
-- -------------------------------------------------------------
safe_setup('better_escape', function()
  require('better_escape').setup {
    timeout = vim.o.timeoutlen,
    default_mappings = false,
    mappings = {
      i = {
        j = { k = '<Esc>', K = '<Esc>' },
        J = { K = '<Esc>' },
      },
    },
  }
end)

-- -------------------------------------------------------------
-- 3. leap.nvim  —  motion (codeberg fork)
-- -------------------------------------------------------------
vim.keymap.set({ 'n', 'x', 'o' }, 's', '<Plug>(leap-forward)', { desc = 'Leap forward' })

-- -------------------------------------------------------------
-- 4. neogit  —  Git UI
-- -------------------------------------------------------------
safe_setup('neogit', function() require('neogit').setup {} end)

-- -------------------------------------------------------------
-- 5. oil.nvim  —  file explorer
-- -------------------------------------------------------------
safe_setup('oil', function()
  require('oil').setup {
    default_file_explorer = true,
    delete_to_trash = true,
    skip_confirm_for_simple_edits = true,
  }
end)
vim.keymap.set('n', 'm', '<cmd>Oil<cr>', { desc = 'Open parent dir (oil)' })

-- -------------------------------------------------------------
-- 6. harpoon v1  —  file marks. Native quick menu is editable.
-- -------------------------------------------------------------
safe_setup('harpoon', function()
  require('harpoon').setup {
    menu = {
      width = 40,
      height = 13,
    },
    global_settings = {
      save_on_toggle = true,
      save_on_change = true,
    },
  }
  local mark = require 'harpoon.mark'
  local ui = require 'harpoon.ui'
  local m = vim.keymap.set
  m('n', '<leader>a', mark.add_file, { desc = 'Harpoon: add file' })
  m('n', '<leader>k', ui.toggle_quick_menu, { desc = 'Harpoon: menu' })
  m('n', '<C-q>', function() ui.nav_file(1) end, { desc = 'Harpoon slot 1' })
  m('n', '<C-w>', function() ui.nav_file(2) end, { desc = 'Harpoon slot 2' })
  m('n', '<C-e>', function() ui.nav_file(3) end, { desc = 'Harpoon slot 3' })
end)

-- -------------------------------------------------------------
-- 7. kulala.nvim  —  HTTP REST. Filetype-gated.
-- -------------------------------------------------------------
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'http', 'json' },
  group = vim.api.nvim_create_augroup('custom-kulala', { clear = true }),
  callback = function(ev)
    safe_setup('kulala', function() require('kulala').setup {} end)
    vim.keymap.set('n', '<leader>r', function() require('kulala').run() end, {
      buffer = ev.buf,
      desc = 'Kulala run',
    })
  end,
})

-- =============================================================
-- C / C++ essentials
-- =============================================================

safe_setup('clangd_extensions', function() require('clangd_extensions').setup {} end)
safe_setup('cmake-tools', function() require('cmake-tools').setup {} end)
safe_setup('zuzu', function() require('zuzu').setup {} end)

vim.keymap.set('n', '<leader>zr', '<cmd>ZuzuRun<cr>', { desc = 'Zuzu run' })
vim.keymap.set('n', '<leader>zb', '<cmd>ZuzuBuild<cr>', { desc = 'Zuzu build' })
vim.keymap.set('n', '<leader>ze', '<cmd>ZuzuEdit<cr>', { desc = 'Zuzu edit profile' })

-- =============================================================
-- snacks.nvim  —  picker module ONLY (Telescope replacement)
-- =============================================================
safe_setup('snacks', function()
  require('snacks').setup {
    picker = {
      layout = { preset = 'default' },
      win = {
        input = {
          keys = {
            ['<C-u>'] = { 'preview_scroll_up', mode = { 'i', 'n' } },
            ['<C-d>'] = { 'preview_scroll_down', mode = { 'i', 'n' } },
            ['<C-j>'] = { 'list_down', mode = { 'i', 'n' } },
            ['<C-k>'] = { 'list_up', mode = { 'i', 'n' } },
          },
        },
      },
      sources = {
        files = { hidden = true },
        grep = { hidden = true },
      },
    },
  }
end)
