-- Shows the Mermaid diagram under the cursor (a ```mermaid fenced block) in a
-- floating window. It renders the block to PNG with `mmdc` (mermaid-cli) and
-- draws it as an iTerm2 inline image (OSC 1337), like pdf-view.nvim does.
local M = {}

local cache_dir = vim.fn.stdpath('cache') .. '/mermaid'

---Source of the mermaid fence around the cursor, or nil.
---@return string?
local function block_at_cursor()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local start
  for i = row, 1, -1 do
    if lines[i]:match('^%s*```+%s*mermaid%s*$') then
      start = i
      break
    elseif i < row and lines[i]:match('^%s*```') then
      return nil -- another fence closes before the cursor
    end
  end
  if not start then
    return nil
  end
  local body = {}
  for i = start + 1, #lines do
    if lines[i]:match('^%s*```') then
      if i < row then
        return nil -- cursor is after the closing fence
      end
      return table.concat(body, '\n')
    end
    body[#body + 1] = lines[i]
  end
  return nil
end

---PNG dimensions from its IHDR header.
local function png_size(data)
  local w = data:byte(17) * 16777216 + data:byte(18) * 65536 + data:byte(19) * 256 + data:byte(20)
  local h = data:byte(21) * 16777216 + data:byte(22) * 65536 + data:byte(23) * 256 + data:byte(24)
  return w, h
end

local function term_write(s)
  if vim.api.nvim_ui_send then
    vim.api.nvim_ui_send(s)
  else
    io.stdout:write(s)
    io.stdout:flush()
  end
end

local ZOOM_STEP = 1.5
local ZOOM_MAX = 40

---Crops `png` to the pixel rectangle and returns the file of the part.
local function crop(png, x, y, w, h)
  local out = ('%s/crop-%d-%d-%d-%d-%s'):format(cache_dir, x, y, w, h, vim.fn.fnamemodify(png, ':t'))
  if not vim.uv.fs_stat(out) then
    local r = vim.system({ 'sips', '-c', tostring(h), tostring(w), '--cropOffset', tostring(y), tostring(x), png, '--out', out }):wait()
    if r.code ~= 0 then
      return png
    end
  end
  return out
end

local function show(png)
  local f = assert(io.open(png, 'rb'))
  local full = f:read('*a')
  f:close()
  local pw, ph = png_size(full)

  -- The float covers the whole editor. The view is a rectangle of the diagram
  -- (in pixels) scaled to fill it, keeping the aspect ratio (a cell is
  -- assumed ~1:2, width:height).
  local win_cols = vim.o.columns
  local win_rows = vim.o.lines - vim.o.cmdheight
  local aspect = win_cols / (win_rows * 2)
  local base_w = math.max(pw, ph * aspect) -- view width that shows everything
  local zoom, cx, cy = 1, pw / 2, ph / 2

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.fn['repeat']({ string.rep(' ', win_cols) }, win_rows))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor', row = 0, col = 0, width = win_cols, height = win_rows,
    style = 'minimal', border = 'none', zindex = 250,
  })

  local seq, row, col
  local function build()
    local vw = base_w / zoom
    local vh = vw / aspect
    local w, h = math.min(pw, vw), math.min(ph, vh)
    cx = math.max(w / 2, math.min(pw - w / 2, cx))
    cy = math.max(h / 2, math.min(ph - h / 2, cy))
    w, h = math.floor(w), math.floor(h)
    local x, y = math.floor(cx - w / 2), math.floor(cy - h / 2)
    local data = full
    if w < pw or h < ph then
      local g = assert(io.open(crop(png, x, y, w, h), 'rb'))
      data = g:read('*a')
      g:close()
    end
    local k = math.min(win_cols / w, win_rows * 2 / h)
    local cols, rows = math.max(1, math.floor(w * k)), math.max(1, math.floor(h * k / 2))
    row, col = math.floor((win_rows - rows) / 2), math.floor((win_cols - cols) / 2)
    seq = ('\27]1337;File=inline=1;size=%d;width=%d;height=%d;preserveAspectRatio=0;doNotMoveCursor=1:%s\a')
      :format(#data, cols, rows, vim.base64.encode(data))
  end
  build()

  -- +1: terminal coordinates are 1-based. Neovim redraws can write
  -- over an inline image, so it is printed again after each redraw of the float.
  local ns = vim.api.nvim_create_namespace('mermaid-image-' .. win)
  local pending = false
  local function draw()
    pending = false
    if vim.api.nvim_win_is_valid(win) then
      term_write(('\27[s\27[%d;%dH%s\27[u'):format(row + 1, col + 1, seq))
    end
  end
  vim.api.nvim_set_decoration_provider(ns, {
    on_win = function(_, w)
      if w == win and not pending then
        pending = true
        vim.defer_fn(draw, 30)
      end
    end,
  })
  local function refresh()
    build()
    vim.cmd('redraw!')
    vim.defer_fn(draw, 30)
  end
  vim.cmd('redraw')
  vim.defer_fn(draw, 60)

  local function close()
    vim.api.nvim_set_decoration_provider(ns, {})
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    vim.cmd('redraw!')
  end
  local function map(keys, fn)
    for _, key in ipairs(type(keys) == 'table' and keys or { keys }) do
      vim.keymap.set('n', key, fn, { buffer = buf, nowait = true })
    end
  end
  local function zoom_by(factor)
    return function()
      zoom = math.max(1, math.min(ZOOM_MAX, zoom * factor))
      refresh()
    end
  end
  local function pan(dx, dy)
    return function()
      local vw = base_w / zoom
      cx, cy = cx + dx * vw, cy + dy * vw / aspect
      refresh()
    end
  end
  map({ 'q', '<Esc>' }, close)
  map({ '+', '=', 'z', '<ScrollWheelUp>' }, zoom_by(ZOOM_STEP))
  map({ '-', 'Z', '<ScrollWheelDown>' }, zoom_by(1 / ZOOM_STEP))
  map({ '0', '<CR>' }, function()
    zoom, cx, cy = 1, pw / 2, ph / 2
    refresh()
  end)
  map({ 'h', '<Left>' }, pan(-0.25, 0))
  map({ 'l', '<Right>' }, pan(0.25, 0))
  map({ 'k', '<Up>' }, pan(0, -0.25))
  map({ 'j', '<Down>' }, pan(0, 0.25))
  vim.api.nvim_create_autocmd('BufLeave', { buffer = buf, once = true, callback = close })
end

function M.preview()
  if vim.fn.executable('mmdc') == 0 then
    vim.notify('mmdc not found: npm i -g @mermaid-js/mermaid-cli', vim.log.levels.ERROR)
    return
  end
  local src = block_at_cursor()
  if not src then
    vim.notify('Cursor is not inside a ```mermaid block', vim.log.levels.WARN)
    return
  end
  vim.fn.mkdir(cache_dir, 'p')
  local name = vim.fn.sha256(src):sub(1, 16) .. '-s3'
  local mmd, png = cache_dir .. '/' .. name .. '.mmd', cache_dir .. '/' .. name .. '.png'
  if vim.uv.fs_stat(png) then
    return show(png)
  end
  vim.fn.writefile(vim.split(src, '\n'), mmd)
  vim.notify('Rendering mermaid diagram…')
  vim.system({ 'mmdc', '-i', mmd, '-o', png, '-b', 'white', '-s', '3', '-q' }, { text = true }, vim.schedule_wrap(function(r)
    if r.code ~= 0 or not vim.uv.fs_stat(png) then
      vim.notify('mmdc failed: ' .. (r.stderr or ''), vim.log.levels.ERROR)
      return
    end
    show(png)
  end))
end

return M
