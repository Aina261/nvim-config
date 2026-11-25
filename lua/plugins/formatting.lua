-- Formatting (conform.nvim) and linting (nvim-lint). Formatters and linters
-- are installed by mason-tool-installer (see lua/plugins/mason_tools.lua).
-- Format on save can be switched off with `<leader>uf`.
local ESLINT_CONFIG_FILES = {
  'eslint.config.js', 'eslint.config.mjs', 'eslint.config.cjs', 'eslint.config.ts',
  '.eslintrc', '.eslintrc.js', '.eslintrc.cjs', '.eslintrc.json', '.eslintrc.yml', '.eslintrc.yaml',
}

local function has_eslint_config(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  return vim.fs.find(ESLINT_CONFIG_FILES, { path = name, upward = true })[1] ~= nil
end

local LINTERS_BY_FILETYPE = {
  python = { 'ruff' },
  javascript = { 'eslint_d' },
  javascriptreact = { 'eslint_d' },
  typescript = { 'eslint_d' },
  typescriptreact = { 'eslint_d' },
  markdown = { 'markdownlint-cli2' },
}

local function run_linters(bufnr)
  local lint = require('lint')
  local names = vim.tbl_filter(function(name)
    if vim.fn.executable(name) == 0 then
      return false
    end
    -- eslint_d reports an error on every file of a project without ESLint.
    return name ~= 'eslint_d' or has_eslint_config(bufnr)
  end, LINTERS_BY_FILETYPE[vim.bo[bufnr].filetype] or {})

  if #names > 0 then
    lint.try_lint(names)
  end
end

return {
  {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    cmd = 'ConformInfo',
    keys = {
      {
        '<leader>cf',
        function()
          require('conform').format({ async = true, lsp_format = 'fallback' })
        end,
        mode = { 'n', 'v' },
        desc = 'Format file',
      },
      {
        '<leader>uf',
        function()
          vim.g.autoformat = not (vim.g.autoformat ~= false)
          vim.notify('Format on save: ' .. (vim.g.autoformat and 'on' or 'off'))
        end,
        desc = 'Toggle format on save',
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { 'stylua' },
        python = { 'ruff_format' },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        vue = { 'prettierd', 'prettier', stop_after_first = true },
        json = { 'prettierd', 'prettier', stop_after_first = true },
        jsonc = { 'prettierd', 'prettier', stop_after_first = true },
        css = { 'prettierd', 'prettier', stop_after_first = true },
        html = { 'prettierd', 'prettier', stop_after_first = true },
        yaml = { 'prettierd', 'prettier', stop_after_first = true },
        markdown = { 'prettierd', 'prettier', stop_after_first = true },
      },
      format_on_save = function()
        if vim.g.autoformat == false then
          return nil
        end
        return { timeout_ms = 1000, lsp_format = 'fallback' }
      end,
    },
  },

  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPost', 'BufWritePost', 'InsertLeave' },
    config = function()
      vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost', 'InsertLeave' }, {
        group = vim.api.nvim_create_augroup('UserLint', { clear = true }),
        callback = function(args)
          run_linters(args.buf)
        end,
      })
      run_linters(vim.api.nvim_get_current_buf())
    end,
  },
}
