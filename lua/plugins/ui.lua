local function get_attached_language_server_names()
  local clients = vim.lsp.get_clients({ bufnr = 0 })

  if #clients == 0 then
    return 'No LSP'
  end

  local names = vim.tbl_map(function(client)
    return client.name
  end, clients)

  return '󰒓 ' .. table.concat(names, ', ')
end

return {
  {
    'folke/tokyonight.nvim',
    priority = 1000,
    config = function()
      vim.cmd.colorscheme('tokyonight-night')
    end,
  },

  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      filters = { git_ignored = false },
      -- The tree is opened in a side split by the config below, never in
      -- place of the directory buffer.
      hijack_directories = { enable = false },
      view = {
        -- Auto-resize to fit the longest filename (min 30 cols, no max)
        width = { min = 30, max = -1, padding = 1 },
      },
      actions = {
        open_file = {
          window_picker = { enable = false },
        },
      },
      on_attach = function(bufnr)
        local api = require('nvim-tree.api')
        api.config.mappings.default_on_attach(bufnr)
        -- The explorer must stay open: remove its close mapping.
        pcall(vim.keymap.del, 'n', 'q', { buffer = bufnr })
      end,
    },
    config = function(_, opts)
      require('nvim-tree').setup(opts)

      local api = require('nvim-tree.api')
      local leaving = false

      -- Set vim.g.nvim_tree_allow_close = true to let the tree close on purpose
      -- (e.g. right before a restart).
      vim.api.nvim_create_autocmd('VimLeavePre', {
        callback = function()
          leaving = true
        end,
      })

      -- Always keep the explorer open: reopen it whenever it gets closed.
      vim.api.nvim_create_autocmd('WinClosed', {
        callback = function(args)
          local buf = vim.api.nvim_win_get_buf(tonumber(args.match))
          if vim.bo[buf].filetype ~= 'NvimTree' then
            return
          end
          vim.schedule(function()
            if leaving or vim.g.nvim_tree_allow_close or api.tree.is_visible() then
              return
            end
            api.tree.open({ focus = false })
          end)
        end,
      })

      -- Open the explorer at startup. `nvim <dir>`: use the directory as cwd
      -- and leave an empty buffer next to the tree.
      local function open_at_startup()
        local arg = vim.fn.argv(0)
        if arg ~= '' and vim.fn.isdirectory(arg) == 1 then
          vim.cmd.cd(vim.fn.fnameescape(arg))
          vim.cmd('enew')
          vim.cmd('silent! bwipeout #')
        end
        api.tree.open({ focus = false })
      end

      if vim.v.vim_did_enter == 1 then
        open_at_startup()
      else
        vim.api.nvim_create_autocmd('VimEnter', { once = true, callback = open_at_startup })
      end
    end,
  },

  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      options = { theme = 'tokyonight' },
      sections = {
        lualine_x = {
          get_attached_language_server_names,
          'encoding',
          'fileformat',
          'filetype',
        },
      },
    },
  },

  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {},
  },
}
