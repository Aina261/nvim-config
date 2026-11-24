local LANGUAGE_SERVERS_TO_INSTALL = { 'lua_ls', 'pyright', 'ts_ls', 'bashls' }

local MASON_ICONS = {
  package_installed = '✓',
  package_pending = '➜',
  package_uninstalled = '✗',
}

-- Only settings are defined: nvim-lspconfig already provides the command,
-- filetypes and root markers of each server, and mason-lspconfig enables
-- every installed server automatically.
local function configure_language_servers()
  vim.lsp.config('*', {
    capabilities = require('blink.cmp').get_lsp_capabilities(),
  })

  vim.lsp.config('lua_ls', {
    settings = {
      Lua = {
        workspace = { checkThirdParty = false },
        telemetry = { enable = false },
      },
    },
  })

  -- Pyright does not discover a project-local virtualenv by itself: point it
  -- at <root>/.venv (uv, poetry in-project, python -m venv) when present, so
  -- installed dependencies resolve instead of reporting missing imports.
  vim.lsp.config('pyright', {
    on_init = function(client)
      local venv_python = (client.root_dir or '') .. '/.venv/bin/python'
      if vim.uv.fs_stat(venv_python) then
        client.settings = vim.tbl_deep_extend('force', client.settings or {}, {
          python = { pythonPath = venv_python },
        })
        client:notify('workspace/didChangeConfiguration', { settings = client.settings })
      end
    end,
  })
end

return {
  -- Configures lua_ls for the Neovim runtime and plugins on demand, instead
  -- of loading the whole runtime into the workspace.
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {},
  },

  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'saghen/blink.cmp',
    },
    config = function()
      require('config.lsp_keymaps')
      require('mason').setup({ ui = { icons = MASON_ICONS } })
      configure_language_servers()
      require('mason-lspconfig').setup({
        ensure_installed = LANGUAGE_SERVERS_TO_INSTALL,
      })
    end,
  },
}
