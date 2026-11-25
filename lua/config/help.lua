-- `:help` without argument opens the keymap cheat sheet (README.md, "Keymaps"
-- section onwards) in a floating window. `:q` (or `q`) closes it.
-- `:help {topic}` keeps working as the regular Neovim help.
local function keymap_lines()
  local path = vim.fs.joinpath(vim.fn.stdpath('config'), 'README.md')
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return { '# Help', '', 'Cannot read ' .. path }
  end
  for index, line in ipairs(lines) do
    if line:match('^## Keymaps') then
      return vim.list_slice(lines, index, #lines)
    end
  end
  return lines
end

local function open_keymap_help()
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, keymap_lines())
  vim.bo[buffer].filetype = 'markdown'
  vim.bo[buffer].bufhidden = 'wipe'
  vim.bo[buffer].modifiable = false

  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor((vim.o.lines - vim.o.cmdheight) * 0.8)
  local window = vim.api.nvim_open_win(buffer, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' Keymaps (:q to close) ',
    title_pos = 'center',
  })
  vim.wo[window].wrap = true
  vim.wo[window].conceallevel = 2

  vim.keymap.set('n', 'q', '<cmd>close<CR>', { buffer = buffer, silent = true, desc = 'Close help' })
end

vim.api.nvim_create_user_command('Help', function(command)
  if command.args == '' then
    open_keymap_help()
  else
    vim.cmd.help({ args = { command.args } })
  end
end, { nargs = '?', complete = 'help', desc = 'Keymap cheat sheet, or :help {topic}' })

-- Typing `:help` (or `:h`) alone runs :Help; with a topic it is the usual help.
for _, name in ipairs({ 'help', 'h' }) do
  vim.cmd(([[cnoreabbrev <expr> %s (getcmdtype() ==# ':' && getcmdline() ==# '%s') ? 'Help' : '%s']]):format(name, name, name))
end
