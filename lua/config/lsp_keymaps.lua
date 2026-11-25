-- Neovim 0.11 already provides K (hover), grn (rename), gra (code action),
-- grr (references) and gri (implementation) on LSP attach, so only the
-- mappings it does not offer are defined here. Formatting (`<leader>cf`) is
-- handled by conform.nvim in lua/plugins/formatting.lua.
local function map_buffer(left_hand_side, right_hand_side, description, bufferNumber)
  vim.keymap.set('n', left_hand_side, right_hand_side, {
    silent = true,
    desc = description,
    buffer = bufferNumber,
  })
end

local function set_lsp_keymaps(bufferNumber)
  map_buffer('gd', vim.lsp.buf.definition, 'Go to definition', bufferNumber)
  map_buffer('gD', vim.lsp.buf.declaration, 'Go to declaration', bufferNumber)
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspKeymaps', { clear = true }),
  callback = function(event)
    set_lsp_keymaps(event.buf)
  end,
})
