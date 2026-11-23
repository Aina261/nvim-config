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
      actions = {
        open_file = {
          window_picker = { enable = false },
        },
      },
    },
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
