-- Non-intrusive diagnostics popup: shown for the current line once the cursor
-- rests on it (`updatetime`, 250ms), never focusable, closed on next movement,
-- always pinned to the bottom-right corner of the window.
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
    local win = vim.api.nvim_get_current_win()
    local _, float = vim.diagnostic.open_float(nil, {
      focus = false,
      max_width = math.max(30, math.floor(vim.api.nvim_win_get_width(win) * 0.5)),
    })
    if not float then return end

    -- Always pin the popup to the bottom-right corner of the window.
    vim.api.nvim_win_set_config(float, {
      relative = 'win',
      win = win,
      anchor = 'SE',
      row = vim.api.nvim_win_get_height(win),
      col = vim.api.nvim_win_get_width(win),
    })
  end,
})
