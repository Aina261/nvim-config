-- Finishing touches: folding, indent guides, nicer cmdline/notifications,
-- breadcrumbs and refactoring helpers.
return {
  {
    'kevinhwang91/nvim-ufo',
    dependencies = { 'kevinhwang91/promise-async' },
    event = 'BufReadPost',
    init = function()
      vim.o.foldcolumn = '1'
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
      vim.o.fillchars = 'eob: ,fold: ,foldopen:▾,foldsep: ,foldclose:▸'
    end,
    opts = {
      provider_selector = function()
        return { 'treesitter', 'indent' }
      end,
    },
    keys = {
      { 'zR', function() require('ufo').openAllFolds() end, desc = 'Open all folds' },
      { 'zM', function() require('ufo').closeAllFolds() end, desc = 'Close all folds' },
    },
  },

  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    event = 'BufReadPost',
    opts = {
      indent = { char = '│' },
      scope = { show_start = false, show_end = false },
    },
  },

  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    dependencies = { 'MunifTanjim/nui.nvim' },
    opts = {
      lsp = {
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        lsp_doc_border = true,
      },
    },
  },

  {
    'Bekaboo/dropbar.nvim',
    event = 'BufReadPost',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {},
  },

  {
    'ThePrimeagen/refactoring.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-treesitter/nvim-treesitter' },
    lazy = false,
    opts = {},
    keys = {
      {
        '<leader>re',
        function() return require('refactoring').extract_func() end,
        mode = { 'n', 'x' },
        expr = true,
        desc = 'Extract function',
      },
      {
        '<leader>rv',
        function() return require('refactoring').extract_var() end,
        mode = { 'n', 'x' },
        expr = true,
        desc = 'Extract variable',
      },
      {
        '<leader>ri',
        function() return require('refactoring').inline_var() end,
        mode = { 'n', 'x' },
        expr = true,
        desc = 'Inline variable',
      },
      {
        '<leader>rs',
        function() return require('refactoring').select_refactor() end,
        mode = { 'n', 'x' },
        desc = 'Select a refactoring',
      },
    },
  },
}
