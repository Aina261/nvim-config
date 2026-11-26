local function map(mode, left_hand_side, right_hand_side, description, extra_options)
  local options = vim.tbl_extend('force', { silent = true, desc = description }, extra_options or {})
  vim.keymap.set(mode, left_hand_side, right_hand_side, options)
end

local function find_in_current_buffer()
  local builtin = require('telescope.builtin')
  local themes = require('telescope.themes')

  builtin.current_buffer_fuzzy_find(themes.get_dropdown({
    winblend = 10,
    previewer = false,
  }))
end

local function jump_to_diagnostic(direction)
  return function()
    vim.diagnostic.jump({ count = direction, float = true })
  end
end

-- Closes nvim-tree before the session is saved, then reopens it once the
-- session is restored, so the tree never ends up in the saved layout.
-- Optional `extra` is a command passed through to `:restart`.
local function restart_nvim(extra)
  extra = extra or ''
  local tree = require('nvim-tree.api').tree
  if tree.is_visible() then
    vim.g.nvim_tree_allow_close = true
    tree.close()
    extra = "lua require('nvim-tree.api').tree.open({ focus = false })"
      .. (extra ~= '' and ('\n' .. extra) or '')
  end
  vim.cmd('restart ' .. extra)
end

-- `:restart` itself is built in and cannot be redefined, so a command-line
-- abbreviation rewrites a typed `:restart` into `:Restart`.
vim.api.nvim_create_user_command('Restart', function(opts)
  restart_nvim(opts.args)
end, { nargs = '*', desc = 'Restart Neovim, keeping nvim-tree open' })
vim.cmd([[cnoreabbrev <expr> restart (getcmdtype() == ':' && getcmdline() ==# 'restart') ? 'Restart' : 'restart']])

local function set_file_and_window_keymaps()
  map('n', '<leader>w', '<cmd>w<CR>', 'Save file')
  map('n', '<leader>q', '<cmd>q<CR>', 'Quit window')
  map('n', '<Esc>', '<cmd>nohlsearch<CR>', 'Clear search highlighting')
  map('n', '<leader>da', '<cmd>%delete _<CR>', 'Delete all file content')
  map('n', '<leader>e', '<cmd>NvimTreeFocus<CR>', 'Open file explorer')

  map('n', '<C-h>', '<C-w>h', 'Go to left window')
  map('n', '<C-j>', '<C-w>j', 'Go to bottom window')
  map('n', '<C-k>', '<C-w>k', 'Go to top window')
  map('n', '<C-l>', '<C-w>l', 'Go to right window')
end

local function set_telescope_keymaps()
  map('n', '<leader>ff', function()
    require('telescope.builtin').find_files()
  end, 'Find file')

  map('n', '<leader>fr', find_in_current_buffer, 'Find text in current file')

  map('n', '<leader>fg', function()
    require('telescope.builtin').live_grep()
  end, 'Search text in project')

  map('n', '<leader>fb', function()
    require('telescope.builtin').buffers()
  end, 'Show open buffers')
end

local function set_diagnostic_and_lsp_management_keymaps()
  map('n', '[d', jump_to_diagnostic(-1), 'Go to previous diagnostic')
  map('n', ']d', jump_to_diagnostic(1), 'Go to next diagnostic')
  map('n', '<leader>xd', vim.diagnostic.open_float, 'Show diagnostic under cursor')
  map('n', '<leader>D', vim.diagnostic.setloclist, 'Show diagnostics list')

  map('n', '<leader>li', '<cmd>checkhealth vim.lsp<CR>', 'Show LSP information')
  map('n', '<leader>lr', '<cmd>lsp restart<CR>', 'Restart LSP')
  map('n', '<leader>m', '<cmd>Mason<CR>', 'Open Mason')
  map('n', '<leader>R', function() restart_nvim() end, 'Restart Neovim and restore the session')
end

set_file_and_window_keymaps()
set_telescope_keymaps()
set_diagnostic_and_lsp_management_keymaps()
