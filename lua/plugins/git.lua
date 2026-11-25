-- Advanced git: side-by-side diffs, file history and merge conflict
-- resolution (gitsigns itself is configured in lua/plugins/editor.lua).
return {
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory', 'DiffviewToggleFiles' },
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-tree/nvim-web-devicons' },
    opts = {},
    keys = {
      { '<leader>gd', '<cmd>DiffviewOpen<CR>', desc = 'Git diff (working tree)' },
      { '<leader>gD', '<cmd>DiffviewOpen origin/HEAD...HEAD<CR>', desc = 'Git diff against origin' },
      { '<leader>gh', '<cmd>DiffviewFileHistory %<CR>', desc = 'Git history of this file' },
      { '<leader>gH', '<cmd>DiffviewFileHistory<CR>', desc = 'Git history of the repository' },
      { '<leader>gq', '<cmd>DiffviewClose<CR>', desc = 'Close git diff' },
    },
  },
}
