-- Non-intrusive diagnostics popup: shown for the current line once the cursor
-- rests on it (`updatetime`, 250ms), never focusable, closed on next movement.
vim.diagnostic.config({
  severity_sort = true,
  float = {
    scope = 'line',
    border = 'rounded',
    source = true,
    focusable = false,
    close_events = { 'CursorMoved', 'CursorMovedI', 'InsertEnter', 'BufLeave', 'FocusLost' },
  },
})

vim.api.nvim_create_autocmd('CursorHold', {
  group = vim.api.nvim_create_augroup('DiagnosticLinePopup', { clear = true }),
  desc = 'Show line diagnostics in a floating window',
  callback = function(args)
    if vim.fn.mode() ~= 'n' or vim.bo[args.buf].buftype ~= '' then return end
    local line = vim.api.nvim_win_get_cursor(0)[1] - 1
    if #vim.diagnostic.get(args.buf, { lnum = line }) == 0 then return end
    vim.diagnostic.open_float(nil, { focus = false })
  end,
})
