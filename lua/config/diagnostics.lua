-- Non-intrusive diagnostics popup: shown for the current line once the cursor
-- rests on it (`updatetime`, 250ms), never focusable, closed on next movement,
-- pinned to the top-right corner of the window (bottom-right if the cursor
-- is near the top, so the popup never covers the current line).
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

    -- Pin the popup to the top-right corner of the window. If the cursor line
    -- is that close to the top, move it to the bottom-right so it never hides
    -- the code being edited.
    local height = vim.api.nvim_win_get_height(float) + 2 -- + border
    local at_top = vim.fn.winline() > height
    vim.api.nvim_win_set_config(float, {
      relative = 'win',
      win = win,
      anchor = at_top and 'NE' or 'SE',
      row = at_top and 0 or vim.api.nvim_win_get_height(win),
      col = vim.api.nvim_win_get_width(win),
    })
  end,
})
