-- Integrated terminal: `<C-\>` toggles a terminal at the bottom, `<leader>tf`
-- a floating one and `<leader>gg` lazygit (needs the `lazygit` binary).
local function toggle_lazygit()
  if vim.fn.executable('lazygit') == 0 then
    vim.notify('lazygit is not installed (brew install lazygit)', vim.log.levels.WARN)
    return
  end

  local lazygit = require('toggleterm.terminal').Terminal:new({
    cmd = 'lazygit',
    direction = 'float',
    hidden = true,
  })
  lazygit:toggle()
end

return {
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    opts = {
      open_mapping = [[<C-\>]],
      direction = 'horizontal',
      size = 15,
      shade_terminals = false,
      float_opts = { border = 'rounded' },
    },
    keys = {
      { [[<C-\>]], desc = 'Toggle terminal', mode = { 'n', 't' } },
      { '<leader>tt', '<cmd>ToggleTerm direction=horizontal<CR>', desc = 'Terminal (bottom)' },
      { '<leader>tf', '<cmd>ToggleTerm direction=float<CR>', desc = 'Terminal (floating)' },
      { '<leader>gg', toggle_lazygit, desc = 'Lazygit' },
    },
    init = function()
      vim.api.nvim_create_autocmd('TermOpen', {
        pattern = 'term://*toggleterm#*',
        callback = function(args)
          local function map(lhs, rhs, desc)
            vim.keymap.set('t', lhs, rhs, { buffer = args.buf, desc = desc })
          end
          map('<Esc><Esc>', [[<C-\><C-n>]], 'Leave terminal mode')
          map('<C-h>', [[<Cmd>wincmd h<CR>]], 'Go to left window')
          map('<C-j>', [[<Cmd>wincmd j<CR>]], 'Go to bottom window')
          map('<C-k>', [[<Cmd>wincmd k<CR>]], 'Go to top window')
          map('<C-l>', [[<Cmd>wincmd l<CR>]], 'Go to right window')
        end,
      })
    end,
  },
}
