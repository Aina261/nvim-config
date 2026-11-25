-- Diagnostics panel (trouble.nvim), symbol outline (aerial.nvim) and TODO
-- comments. Everything lives under `<leader>x` except the outline (`<leader>o`).
return {
  {
    'folke/trouble.nvim',
    cmd = 'Trouble',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {},
    keys = {
      { '<leader>xx', '<cmd>Trouble diagnostics toggle<CR>', desc = 'Diagnostics (project)' },
      { '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<CR>', desc = 'Diagnostics (buffer)' },
      { '<leader>xs', '<cmd>Trouble symbols toggle focus=false<CR>', desc = 'Symbols' },
      { '<leader>xl', '<cmd>Trouble lsp toggle focus=false win.position=right<CR>', desc = 'LSP definitions / references' },
      { '<leader>xL', '<cmd>Trouble loclist toggle<CR>', desc = 'Location list' },
      { '<leader>xq', '<cmd>Trouble qflist toggle<CR>', desc = 'Quickfix list' },
      { '<leader>xt', '<cmd>Trouble todo toggle<CR>', desc = 'TODO comments' },
    },
  },

  {
    'stevearc/aerial.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    cmd = { 'AerialToggle', 'AerialNavToggle' },
    opts = {
      backends = { 'lsp', 'treesitter', 'markdown', 'man' },
      layout = { default_direction = 'right', min_width = 30 },
      show_guides = true,
    },
    keys = {
      { '<leader>o', '<cmd>AerialToggle!<CR>', desc = 'Symbol outline' },
      { '{', '<cmd>AerialPrev<CR>', desc = 'Previous symbol' },
      { '}', '<cmd>AerialNext<CR>', desc = 'Next symbol' },
    },
  },

  {
    'folke/todo-comments.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {},
    keys = {
      { ']t', function() require('todo-comments').jump_next() end, desc = 'Next TODO comment' },
      { '[t', function() require('todo-comments').jump_prev() end, desc = 'Previous TODO comment' },
      { '<leader>ft', '<cmd>TodoTelescope<CR>', desc = 'Find TODO comments' },
    },
  },
}
