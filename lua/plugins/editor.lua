local TREESITTER_PARSERS = {
  'lua',
  'python',
  'javascript',
  'typescript',
  'bash',
  'vim',
  'vimdoc',
  'markdown',
  'markdown_inline',
}

local TREESITTER_FILETYPES = {
  'lua',
  'python',
  'javascript',
  'typescript',
  'sh',
  'bash',
  'vim',
  'help',
  'markdown',
}

local function enable_treesitter_for_filetypes()
  vim.api.nvim_create_autocmd('FileType', {
    pattern = TREESITTER_FILETYPES,
    callback = function()
      vim.treesitter.start()
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
  })
end

return {
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('telescope').setup()
    end,
  },

  -- The `main` branch is a rewrite: parsers are installed explicitly and
  -- highlighting and indentation are enabled per filetype.
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').install(TREESITTER_PARSERS)
      enable_treesitter_for_filetypes()
    end,
  },

  {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end,
  },

  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      require('nvim-autopairs').setup()
    end,
  },

  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup()
    end,
  },
}
