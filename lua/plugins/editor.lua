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
  -- Highlights ```mermaid fenced blocks inside Markdown (injected by name).
  'mermaid',
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
    -- 0.1.x calls the removed parsers.ft_to_lang of nvim-treesitter `main`
    branch = 'master',
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
      require('gitsigns').setup({
        on_attach = function(bufnr)
          local gs = require('gitsigns')
          local function map(lhs, rhs, desc)
            vim.keymap.set('n', lhs, rhs, { buffer = bufnr, desc = desc })
          end

          map('<leader>gb', function()
            gs.blame_line({ full = true })
          end, 'Git blame current line (popup)')
          -- gitsigns' blame is not a toggle: calling it again while the blame
          -- window is open fails with E95, so close the open window instead.
          map('<leader>gB', function()
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
              local buf = vim.api.nvim_win_get_buf(win)
              if vim.bo[buf].filetype == 'gitsigns-blame' then
                vim.api.nvim_win_close(win, true)
                return
              end
            end
            gs.blame()
          end, 'Toggle git blame of the whole file (side window)')
          map('<leader>gt', gs.toggle_current_line_blame, 'Toggle inline git blame')
        end,
      })
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
      { '<leader>mm', function() require('mermaid').preview() end, ft = 'markdown', desc = 'Show the Mermaid diagram under the cursor' },
    },
  },
}
