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

local ZOOM_STEP = 2
local ZOOM_MAX = 40
local DEBOUNCE_MS = 25
local CELL_PX = 14 -- pixels per cell, roughly, to size what is sent to the terminal
local CURSOR_STEP = { rows = 2, cols = 4 } -- cells moved by one h/j/k/l, so both axes feel alike

local function read_file(path)
  local f = assert(io.open(path, 'rb'))
  local d = f:read('*a')
  f:close()
  return d
end

---Makes the part (x, y, w, h) of `png` as a PNG of ow x oh pixels (the size it is shown at: sending anything
---bigger to the terminal only makes it slow). Runs `sips` in the background and calls `cb(file)`; at once when
---the file already exists.
local function make_view(png, x, y, w, h, ow, oh, cb)
  local out = ('%s/view-%d-%d-%d-%d-%dx%d-%s'):format(cache_dir, x, y, w, h, ow, oh, vim.fn.fnamemodify(png, ':t'))
  if vim.uv.fs_stat(out) then
    return cb(out)
  end
  -- sips does not combine -c and -z reliably, so: crop to a temp file, then resample
  local tmp = out .. '.tmp.png'
  local function resample(src)
    vim.system({ 'sips', '--resampleHeightWidth', tostring(oh), tostring(ow), src, '--out', out }, {}, vim.schedule_wrap(function(r)
      pcall(os.remove, tmp)
      cb(r.code == 0 and out or png)
    end))
  end
  vim.system(
    { 'sips', '-c', tostring(h), tostring(w), '--cropOffset', tostring(y), tostring(x), png, '--out', tmp },
    {},
    vim.schedule_wrap(function(r)
      if r.code ~= 0 then
        return cb(png)
      end
      resample(tmp)
    end)
  )
end

local function show(png)
  local pw, ph = png_size(read_file(png))

  -- The float covers the whole editor. The view is a rectangle of the diagram
  -- (in pixels) scaled to fill it, keeping the aspect ratio (a cell is
  -- assumed ~1:2, width:height). The terminal cursor is the zoom cursor: it
  -- moves for free, and `+` zooms in on the cell it is on.
  local win_cols = vim.o.columns
  local win_rows = vim.o.lines - vim.o.cmdheight
  local aspect = win_cols / (win_rows * 2)
  local base_w = math.max(pw, ph * aspect) -- view width that shows everything
  local view_w, cx, cy = base_w, pw / 2, ph / 2

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.fn['repeat']({ string.rep(' ', win_cols) }, win_rows))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor', row = 0, col = 0, width = win_cols, height = win_rows,
    style = 'minimal', border = 'none', zindex = 250,
  })
  vim.api.nvim_win_set_cursor(win, { math.ceil(win_rows / 2), math.floor(win_cols / 2) })

  local view -- { x, y, w, h } in pixels of what is on screen
  local img_seq, row, col, cols, rows
  local gen = 0

  -- Neovim redraws can write over an inline image, so it is printed again
  -- after each redraw of the float (see the decoration provider).
  local ns = vim.api.nvim_create_namespace('mermaid-image-' .. win)
  local pending = false
  local function draw()
    pending = false
    if img_seq and vim.api.nvim_win_is_valid(win) then
      term_write(('\27[s\27[%d;%dH%s\27[u'):format(row + 1, col + 1, img_seq))
    end
  end
  local function schedule_draw()
    if not pending then
      pending = true
      vim.defer_fn(draw, 30)
    end
  end
  vim.api.nvim_set_decoration_provider(ns, {
    on_win = function(_, w)
      if w == win then
        schedule_draw()
      end
    end,
  })

  ---Recomputes the view, makes its image (async), then prints it.
  local function render()
    gen = gen + 1
    local my = gen
    view_w = math.max(base_w / ZOOM_MAX, math.min(base_w, view_w))
    local w, h = math.min(pw, view_w), math.min(ph, view_w / aspect)
    cx = math.max(w / 2, math.min(pw - w / 2, cx))
    cy = math.max(h / 2, math.min(ph - h / 2, cy))
    w, h = math.floor(w), math.floor(h)
    local x, y = math.floor(cx - w / 2), math.floor(cy - h / 2)
    local k = math.min(win_cols / w, win_rows * 2 / h)
    cols, rows = math.max(1, math.floor(w * k)), math.max(1, math.floor(h * k / 2))
    row, col = math.floor((win_rows - rows) / 2), math.floor((win_cols - cols) / 2)
    view = { x = x, y = y, w = w, h = h }

    local ow = math.min(w, cols * CELL_PX)
    local oh = math.max(1, math.floor(h * ow / w))
    make_view(png, x, y, w, h, ow, oh, function(file)
      if my ~= gen or not vim.api.nvim_win_is_valid(win) then
        return -- a newer render replaced this one
      end
      local data = read_file(file)
      img_seq = ('\27]1337;File=inline=1;size=%d;width=%d;height=%d;preserveAspectRatio=0;doNotMoveCursor=1:%s\a')
        :format(#data, cols, rows, vim.base64.encode(data))
      vim.cmd('redraw!') -- on_win then prints the image
    end)
  end

  -- Several quick key presses are merged into one render.
  local timer = assert(vim.uv.new_timer())
  local function schedule()
    timer:stop()
    timer:start(DEBOUNCE_MS, 0, vim.schedule_wrap(render))
  end

  local closed = false
  local function close()
    if closed then
      return
    end
    closed = true
    timer:stop()
    timer:close()
    gen = gen + 1
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

  ---Point of the diagram (pixels) under the cursor, clamped to the view.
  local function cursor_point()
    local r, c = unpack(vim.api.nvim_win_get_cursor(win))
    local fx = math.max(0, math.min(1, (c - col + 0.5) / cols))
    local fy = math.max(0, math.min(1, (r - 1 - row + 0.5) / rows))
    return view.x + fx * view.w, view.y + fy * view.h
  end
  local function center_cursor()
    vim.api.nvim_win_set_cursor(win, { row + math.ceil(rows / 2), col + math.floor(cols / 2) })
  end
  local function zoom(factor)
    return function()
      cx, cy = cursor_point()
      view_w = view_w / factor
      schedule()
      -- the cursor ends up on the point that was zoomed on, i.e. the view's centre
      vim.defer_fn(function()
        if not closed and vim.api.nvim_win_is_valid(win) then
          center_cursor()
        end
      end, DEBOUNCE_MS + 5)
    end
  end
  local function move_cursor(dr, dc)
    return function()
      local r, c = unpack(vim.api.nvim_win_get_cursor(win))
      r = math.max(1, math.min(win_rows, r + dr * CURSOR_STEP.rows))
      c = math.max(0, math.min(win_cols - 1, c + dc * CURSOR_STEP.cols))
      vim.api.nvim_win_set_cursor(win, { r, c })
    end
  end
  local function pan(dx, dy)
    return function()
      cx, cy = cx + dx * view.w, cy + dy * view.h
      schedule()
    end
  end
  map({ 'q', '<Esc>' }, close)
  map({ '+', '=', '<CR>', '<ScrollWheelUp>' }, zoom(ZOOM_STEP))
  map({ '-', '<BS>', '<ScrollWheelDown>' }, zoom(1 / ZOOM_STEP))
  map('0', function()
    view_w, cx, cy = base_w, pw / 2, ph / 2
    schedule()
    vim.defer_fn(center_cursor, DEBOUNCE_MS + 5)
  end)
  map({ 'h', '<Left>' }, move_cursor(0, -1))
  map({ 'l', '<Right>' }, move_cursor(0, 1))
  map({ 'k', '<Up>' }, move_cursor(-1, 0))
  map({ 'j', '<Down>' }, move_cursor(1, 0))
  map({ 'H', '<S-Left>' }, pan(-0.25, 0))
  map({ 'L', '<S-Right>' }, pan(0.25, 0))
  map({ 'K', '<S-Up>' }, pan(0, -0.25))
  map({ 'J', '<S-Down>' }, pan(0, 0.25))
  vim.api.nvim_create_autocmd('BufLeave', { buffer = buf, once = true, callback = close })

  vim.cmd('redraw')
  render()
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
