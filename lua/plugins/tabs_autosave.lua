-- Close a buffer and go back to the previously used one (alternate buffer).
local function close_buf(bufnr)
  bufnr = (bufnr and bufnr ~= 0) and bufnr or vim.api.nvim_get_current_buf()
  if vim.api.nvim_get_current_buf() == bufnr then
    local alt = vim.fn.bufnr('#')
    if alt > 0 and alt ~= bufnr and vim.api.nvim_buf_is_valid(alt) and vim.bo[alt].buflisted then
      vim.cmd('buffer ' .. alt)
    end
  end
  vim.cmd('bdelete ' .. bufnr)
end

return {
  {
    'akinsho/bufferline.nvim',
    version = '*',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'VeryLazy',
    opts = {
      options = {
        mode = 'buffers',
        diagnostics = 'nvim_lsp',
        always_show_bufferline = true,
        close_command = close_buf,
        right_mouse_command = close_buf,
        offsets = {
          { filetype = 'NvimTree', text = 'Explorer', text_align = 'left', separator = true },
        },
      },
    },
    keys = {
      { '<S-l>', '<cmd>BufferLineCycleNext<CR>', desc = 'Next tab' },
      { '<S-h>', '<cmd>BufferLineCyclePrev<CR>', desc = 'Previous tab' },
      { '<leader>bd', close_buf, desc = 'Close tab' },
      { '<leader>bo', '<cmd>BufferLineCloseOthers<CR>', desc = 'Close other tabs' },
      { '<leader>bp', '<cmd>BufferLinePick<CR>', desc = 'Pick tab' },
      { '<leader>bh', '<cmd>BufferLineMovePrev<CR>', desc = 'Move tab left' },
      { '<leader>bl', '<cmd>BufferLineMoveNext<CR>', desc = 'Move tab right' },
    },
  },

  {
    -- Autosave after changes (no plugin needed)
    name = 'autosave',
    dir = vim.fn.stdpath('config'),
    event = 'VeryLazy',
    config = function()
      local timer = assert(vim.uv.new_timer())

      local function save(buf)
        if vim.api.nvim_buf_is_valid(buf)
          and vim.bo[buf].modified
          and vim.bo[buf].buftype == ''
          and vim.api.nvim_buf_get_name(buf) ~= '' then
          vim.api.nvim_buf_call(buf, function()
            vim.cmd('silent! write')
          end)
        end
      end

      vim.api.nvim_create_autocmd({ 'InsertLeave', 'TextChanged' }, {
        group = vim.api.nvim_create_augroup('AutoSave', { clear = true }),
        callback = function(args)
          timer:stop()
          timer:start(500, 0, vim.schedule_wrap(function() save(args.buf) end))
        end,
      })
      vim.api.nvim_create_autocmd({ 'FocusLost', 'BufLeave' }, {
        group = 'AutoSave',
        callback = function(args) save(args.buf) end,
      })
    end,
  },
}
