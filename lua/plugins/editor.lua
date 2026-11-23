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

  -- Renders PDF pages with MuPDF's `mutool` and draws them as iTerm2 inline
  -- images. It must load at startup to take over `*.pdf` buffers.
  {
    'rohit746/pdf-view.nvim',
    lazy = false,
    opts = {},
  },

  -- The upstream GitHub repository is spelled `sqliteviwer.nvim` (the
  -- `sqlite-viewer.nvim` name from its README does not exist), so `main` points
  -- lazy.nvim to the real Lua module. It must load at startup to take over
  -- `*.db` buffers. Requires the `sqlite3` binary.
  {
    'timwmillard/sqliteviwer.nvim',
    main = 'sqlite-viewer',
    lazy = false,
    opts = {},
  },

  -- Renders Markdown inside the buffer (headings, lists, code blocks, tables).
  -- `<leader>mp` toggles the rendering in `.md` buffers (see `keys` below).
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = 'markdown',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    opts = {},
    keys = {
      { '<leader>mp', '<cmd>RenderMarkdown buf_toggle<CR>', ft = 'markdown', desc = 'Toggle Markdown rendering' },
    },
  },
}
