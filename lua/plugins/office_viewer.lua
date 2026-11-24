return {
  -- Local plugin (see `lua/office_viewer.lua`): read-only viewer for `.xlsx`,
  -- `.xlsm` and `.docx` files, rendered as Markdown. Requires `unzip`.
  -- It must load at startup to take over those buffers.
  {
    name = 'office-viewer',
    dir = vim.fn.stdpath('config'),
    lazy = false,
    config = function()
      require('office_viewer').setup()
    end,
  },
}
