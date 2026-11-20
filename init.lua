-- Neovim IDE configuration (requires Neovim 0.11+).
-- The leader keys must be set before any keymap or plugin is loaded.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('config.options')
require('config.keymaps')
require('config.lazy')

print('✓ Neovim IDE configuration loaded!')
