local lazy_path = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

local function install_lazy_if_missing()
  if (vim.uv or vim.loop).fs_stat(lazy_path) then
    return
  end

  local clone_output = vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    '--branch=stable',
    'https://github.com/folke/lazy.nvim.git',
    lazy_path,
  })

  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { clone_output, 'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

install_lazy_if_missing()

vim.opt.rtp:prepend(lazy_path)

require('lazy').setup({ spec = { { import = 'plugins' } } })
