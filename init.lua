-- Neovim IDE Configuration (Compatible with Neovim 0.11+)

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- ============================================================
-- Basic options
-- ============================================================

local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.mouse = 'a'
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.wrap = false
opt.breakindent = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.clipboard = 'unnamedplus'
opt.termguicolors = true
opt.signcolumn = 'yes'
opt.updatetime = 250
opt.scrolloff = 10
opt.splitright = true
opt.splitbelow = true

-- ============================================================
-- Helpers
-- ============================================================

local function map(mode, lhs, rhs, desc, extra_opts)
  local opts = vim.tbl_extend('force', { silent = true, desc = desc }, extra_opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

local function find_in_current_buffer()
  local builtin = require('telescope.builtin')
  local themes = require('telescope.themes')

  builtin.current_buffer_fuzzy_find(themes.get_dropdown({
    winblend = 10,
    previewer = false,
  }))
end

-- ============================================================
-- Keybindings
-- Important: <leader> = SPACE
-- Example: <leader>ff = SPACE + f + f
-- ============================================================

local function set_global_keymaps()
  -- Shortcut: SPACE + w
  -- Action: save the current file
  map('n', '<leader>w', '<cmd>w<CR>', 'Save file')

  -- Shortcut: SPACE + q
  -- Action: quit the current window
  map('n', '<leader>q', '<cmd>q<CR>', 'Quit window')

  -- Shortcut: Esc
  -- Action: remove highlighting from the last search
  map('n', '<Esc>', '<cmd>nohlsearch<CR>', 'Clear search highlighting')

  -- Shortcut: SPACE + d + a
  -- Action: delete all content from the current file
  map('n', '<leader>da', '<cmd>%delete _<CR>', 'Delete all file content')

  -- Shortcut: SPACE + e
  -- Action: open the file explorer
  map('n', '<leader>e', '<cmd>NvimTreeFocus<CR>', 'Open file explorer')

  -- Shortcut: SPACE + f + f
  -- Action: search for a file in the project
  map('n', '<leader>ff', function()
    require('telescope.builtin').find_files()
  end, 'Find file')

  -- Shortcut: SPACE + f + r
  -- Action: search for text in the current file
  map('n', '<leader>fr', find_in_current_buffer, 'Find text in current file')

  -- Shortcut: SPACE + f + g
  -- Action: search for text in all project files
  map('n', '<leader>fg', function()
    require('telescope.builtin').live_grep()
  end, 'Search text in project')

  -- Shortcut: SPACE + f + b
  -- Action: display the list of already-open files
  map('n', '<leader>fb', function()
    require('telescope.builtin').buffers()
  end, 'Show open buffers')

  -- Shortcut: Ctrl + h
  -- Action: go to the left window
  map('n', '<C-h>', '<C-w>h', 'Go to left window')

  -- Shortcut: Ctrl + j
  -- Action: go to the bottom window
  map('n', '<C-j>', '<C-w>j', 'Go to bottom window')

  -- Shortcut: Ctrl + k
  -- Action: go to the top window
  map('n', '<C-k>', '<C-w>k', 'Go to top window')

  -- Shortcut: Ctrl + l
  -- Action: go to the right window
  map('n', '<C-l>', '<C-w>l', 'Go to right window')

  -- Shortcut: [ + d
  -- Action: go to the previous diagnostic
  map('n', '[d', vim.diagnostic.goto_prev, 'Go to previous diagnostic')

  -- Shortcut: ] + d
  -- Action: go to the next diagnostic
  map('n', ']d', vim.diagnostic.goto_next, 'Go to next diagnostic')

  -- Shortcut: SPACE + d
  -- Action: display error details under the cursor
  map('n', '<leader>d', vim.diagnostic.open_float, 'Show diagnostic under cursor')

  -- Shortcut: SPACE + Shift + d
  -- Action: display the file diagnostics list
  map('n', '<leader>D', vim.diagnostic.setloclist, 'Show diagnostics list')

  -- Shortcut: SPACE + l + i
  -- Action: display LSP information
  map('n', '<leader>li', '<cmd>LspInfo<CR>', 'Show LSP information')

  -- Shortcut: SPACE + l + r
  -- Action: restart the LSP
  map('n', '<leader>lr', '<cmd>LspRestart<CR>', 'Restart LSP')

  -- Shortcut: SPACE + m
  -- Action: open Mason
  map('n', '<leader>m', '<cmd>Mason<CR>', 'Open Mason')
end

local function set_lsp_keymaps(bufnr)
  -- Shortcut: g + d
  -- Action: go to the definition of the item under the cursor
  map('n', 'gd', vim.lsp.buf.definition, 'Go to definition', { buffer = bufnr })

  -- Shortcut: g + Shift + d
  -- Action: go to the declaration of the item under the cursor
  map('n', 'gD', vim.lsp.buf.declaration, 'Go to declaration', { buffer = bufnr })

  -- Shortcut: g + i
  -- Action: go to the implementation of the item under the cursor
  map('n', 'gi', vim.lsp.buf.implementation, 'Go to implementation', { buffer = bufnr })

  -- Shortcut: g + r
  -- Action: show where the item is used
  map('n', 'gr', vim.lsp.buf.references, 'Show references', { buffer = bufnr })

  -- Shortcut: Shift + k
  -- Action: display documentation for the item under the cursor
  map('n', 'K', vim.lsp.buf.hover, 'Show documentation', { buffer = bufnr })

  -- Shortcut: SPACE + r + n
  -- Action: rename the item throughout the project
  map('n', '<leader>rn', vim.lsp.buf.rename, 'Rename symbol', { buffer = bufnr })

  -- Shortcut: SPACE + c + a
  -- Action: display available automatic actions
  map('n', '<leader>ca', vim.lsp.buf.code_action, 'Show code actions', { buffer = bufnr })

  -- Shortcut: SPACE + f
  -- Action: format the current file
  map('n', '<leader>f', function()
    vim.lsp.buf.format({ async = true })
  end, 'Format file', { buffer = bufnr })
end

-- Enable global keybindings
set_global_keymaps()

-- ============================================================
-- Automatic lazy.nvim installation
-- ============================================================

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    '--branch=stable',
    'https://github.com/folke/lazy.nvim.git',
    lazypath,
  })

  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

opt.rtp:prepend(lazypath)

-- ============================================================
-- Plugins
-- ============================================================

require('lazy').setup({
  -- Theme
  {
    'folke/tokyonight.nvim',
    priority = 1000,
    config = function()
      vim.cmd.colorscheme('tokyonight-night')
    end,
  },

  -- File explorer
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('nvim-tree').setup({
        actions = {
          open_file = {
            window_picker = {
              enable = false,
            },
          },
        },
      })
    end,
  },

  -- Fuzzy finder
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('telescope').setup()
    end,
  },

  -- Syntax highlighting
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').setup({
        ensure_installed = {
          'lua',
          'python',
          'javascript',
          'typescript',
          'bash',
          'vim',
          'vimdoc',
          'markdown',
          'markdown_inline',
        },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- Comments
  {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end,
  },

  -- LSP + Mason
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
    },
    config = function()
      require('mason').setup({
        ui = {
          icons = {
            package_installed = '✓',
            package_pending = '➜',
            package_uninstalled = '✗',
          },
        },
      })

      require('mason-lspconfig').setup({
        ensure_installed = { 'lua_ls', 'pyright', 'ts_ls', 'bashls' },
        automatic_installation = true,
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()

      local on_attach = function(_, bufnr)
        set_lsp_keymaps(bufnr)
      end

      local servers = {
        lua_ls = {
          cmd = { 'lua-language-server' },
          filetypes = { 'lua' },
          root_markers = {
            { '.luarc.json', '.luarc.jsonc' },
            '.luacheckrc',
            '.stylua.toml',
            'stylua.toml',
            'selene.toml',
            'selene.yml',
            '.git',
          },
          settings = {
            Lua = {
              diagnostics = {
                globals = { 'vim' },
              },
              workspace = {
                library = vim.api.nvim_get_runtime_file('', true),
                checkThirdParty = false,
              },
              telemetry = { enable = false },
            },
          },
        },

        pyright = {
          cmd = { 'pyright-langserver', '--stdio' },
          filetypes = { 'python' },
          root_markers = {
            'pyproject.toml',
            'setup.py',
            'setup.cfg',
            'requirements.txt',
            'Pipfile',
            '.git',
          },
        },

        ts_ls = {
          cmd = { 'typescript-language-server', '--stdio' },
          filetypes = {
            'javascript',
            'javascriptreact',
            'javascript.jsx',
            'typescript',
            'typescriptreact',
            'typescript.tsx',
          },
          root_markers = { 'package.json', 'tsconfig.json', 'jsconfig.json', '.git' },
        },

        bashls = {
          cmd = { 'bash-language-server', 'start' },
          filetypes = { 'sh', 'bash' },
          root_markers = { '.git' },
        },
      }

      for name, config in pairs(servers) do
        vim.lsp.config(name, vim.tbl_deep_extend('force', {
          capabilities = capabilities,
          on_attach = on_attach,
        }, config))
      end

      vim.lsp.enable(vim.tbl_keys(servers))
    end,
  },

  -- Status line
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup({
        options = {
          theme = 'tokyonight',
        },
        sections = {
          lualine_x = {
            {
              function()
                local clients = vim.lsp.get_clients({ bufnr = 0 })
                if #clients == 0 then
                  return 'No LSP'
                end

                local names = {}
                for _, client in ipairs(clients) do
                  table.insert(names, client.name)
                end

                return '󰒓 ' .. table.concat(names, ', ')
              end,
            },
            'encoding',
            'fileformat',
            'filetype',
          },
        },
      })
    end,
  },

  -- Keybinding helper
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    config = function()
      require('which-key').setup()
    end,
  },

  -- Automatic closing of brackets and quotes
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      require('nvim-autopairs').setup()
    end,
  },

  -- Git signs in the gutter
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup()
    end,
  },
})

print('✓ Neovim IDE configuration loaded!')
