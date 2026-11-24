-- Read-only viewer for Office Open XML files (.xlsx, .xlsm, .docx).
-- Files are unzipped with the `unzip` binary and the XML is converted to
-- Markdown text, shown in a non-modifiable buffer. No other dependency.
local M = {}

local MAX_ROWS = 5000 -- per sheet
local MAX_CELL_WIDTH = 60

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

---Reads one file of the zip archive. Returns nil when it does not exist.
---@param path string
---@param member string
---@return string|nil
local function unzip(path, member)
  local res = vim.system({ 'unzip', '-p', path, member }, { text = true }):wait()
  if res.code ~= 0 or not res.stdout or res.stdout == '' then
    return nil
  end
  return res.stdout
end

local function decode(s)
  s = s:gsub('&#x(%x+);', function(h)
    return vim.fn.nr2char(tonumber(h, 16))
  end)
  s = s:gsub('&#(%d+);', function(d)
    return vim.fn.nr2char(tonumber(d))
  end)
  s = s:gsub('&lt;', '<'):gsub('&gt;', '>'):gsub('&quot;', '"'):gsub('&apos;', "'"):gsub('&amp;', '&')
  return s
end

---Concatenates every `<t>` text node found in a XML fragment.
---@param xml string
---@param tag string 't' (shared strings) or 'w:t' (docx)
local function text_nodes(xml, tag)
  local out = {}
  for body in xml:gmatch('<' .. tag .. '[^>/]*>(.-)</' .. tag .. '>') do
    out[#out + 1] = decode(body)
  end
  return table.concat(out)
end

local function attr(attrs, name)
  return attrs:match('%f[%w:]' .. name .. '="([^"]*)"')
end

local function col_to_index(letters)
  local n = 0
  for c in letters:gmatch('%a') do
    n = n * 26 + (c:upper():byte() - 64)
  end
  return n
end

local function index_to_col(n)
  local s = ''
  while n > 0 do
    local r = (n - 1) % 26
    s = string.char(65 + r) .. s
    n = math.floor((n - 1) / 26)
  end
  return s
end

local function clean_cell(s)
  s = s:gsub('[\r\n\t]+', ' '):gsub('|', '\\|')
  if vim.fn.strchars(s) > MAX_CELL_WIDTH then
    s = vim.fn.strcharpart(s, 0, MAX_CELL_WIDTH - 1) .. '…'
  end
  return s
end

---Renders a matrix of strings as an aligned Markdown table.
---@param header string[]
---@param rows string[][]
---@param ncols integer
local function md_table(header, rows, ncols)
  local widths = {}
  for c = 1, ncols do
    widths[c] = math.max(3, vim.fn.strdisplaywidth(header[c] or ''))
  end
  for _, row in ipairs(rows) do
    for c = 1, ncols do
      widths[c] = math.max(widths[c], vim.fn.strdisplaywidth(row[c] or ''))
    end
  end
  local function fmt(row)
    local cells = {}
    for c = 1, ncols do
      local v = row[c] or ''
      cells[c] = v .. string.rep(' ', widths[c] - vim.fn.strdisplaywidth(v))
    end
    return '| ' .. table.concat(cells, ' | ') .. ' |'
  end
  local sep = {}
  for c = 1, ncols do
    sep[c] = string.rep('-', widths[c])
  end
  local lines = { fmt(header), '| ' .. table.concat(sep, ' | ') .. ' |' }
  for _, row in ipairs(rows) do
    lines[#lines + 1] = fmt(row)
  end
  return lines
end

---------------------------------------------------------------------------
-- XLSX / XLSM
---------------------------------------------------------------------------

local function shared_strings(path)
  local xml = unzip(path, 'xl/sharedStrings.xml')
  local list = {}
  if not xml then
    return list
  end
  for si in xml:gmatch('<si>(.-)</si>') do
    si = si:gsub('<rPh.-</rPh>', '') -- phonetic hints
    list[#list + 1] = text_nodes(si, 't')
  end
  return list
end

---@return {name: string, target: string}[]
local function sheet_list(path)
  local wb = unzip(path, 'xl/workbook.xml')
  if not wb then
    return {}
  end
  local rels = unzip(path, 'xl/_rels/workbook.xml.rels') or ''
  local targets = {}
  for a in rels:gmatch('<Relationship%s([^>]*)>') do
    local id, target = attr(a, 'Id'), attr(a, 'Target')
    if id and target then
      targets[id] = target
    end
  end
  local sheets = {}
  for a in wb:gmatch('<sheet%s([^>]*)>') do
    local name, rid = attr(a, 'name'), attr(a, 'r:id')
    local target = rid and targets[rid]
    if name and target then
      target = target:gsub('^/', '')
      if not target:match('^xl/') then
        target = 'xl/' .. target
      end
      sheets[#sheets + 1] = { name = decode(name), target = target }
    end
  end
  return sheets
end

local function render_sheet(xml, strings)
  local rows, row_ids, maxcol = {}, {}, 0
  local pos = 1
  while true do
    local s, e, attrs = xml:find('<c%s([^>]*)>', pos)
    if not s then
      break
    end
    local inner
    if attrs:sub(-1) == '/' then
      pos = e + 1 -- empty cell
    else
      local close_s, close_e = xml:find('</c>', e + 1, true)
      if not close_s then
        break
      end
      inner = xml:sub(e + 1, close_s - 1)
      pos = close_e + 1
    end

    local ref = attr(attrs, 'r')
    if inner and ref then
      local letters, rownum = ref:match('^(%a+)(%d+)$')
      if letters then
        local t = attr(attrs, 't')
        local v = inner:match('<v>(.-)</v>')
        local value
        if t == 's' and v then
          value = strings[tonumber(v) + 1]
        elseif t == 'inlineStr' then
          value = text_nodes(inner, 't')
        elseif t == 'b' and v then
          value = v == '1' and 'TRUE' or 'FALSE'
        elseif v then
          value = decode(v)
        end
        if value and value ~= '' then
          local r, c = tonumber(rownum), col_to_index(letters)
          if not rows[r] then
            rows[r] = {}
            row_ids[#row_ids + 1] = r
          end
          rows[r][c] = clean_cell(value)
          maxcol = math.max(maxcol, c)
        end
      end
    end
  end

  if #row_ids == 0 then
    return { '_(empty sheet)_' }
  end
  table.sort(row_ids)

  local header = { '#' }
  for c = 1, maxcol do
    header[c + 1] = index_to_col(c)
  end
  local body = {}
  local truncated = #row_ids > MAX_ROWS
  for i = 1, math.min(#row_ids, MAX_ROWS) do
    local r = row_ids[i]
    local line = { tostring(r) }
    for c = 1, maxcol do
      line[c + 1] = rows[r][c] or ''
    end
    body[#body + 1] = line
  end
  local lines = md_table(header, body, maxcol + 1)
  if truncated then
    lines[#lines + 1] = ''
    lines[#lines + 1] = ('_Truncated: showing the first %d of %d rows._'):format(MAX_ROWS, #row_ids)
  end
  return lines
end

local function render_xlsx(path)
  local sheets = sheet_list(path)
  if #sheets == 0 then
    return { 'Could not read any sheet from ' .. path }
  end
  local strings = shared_strings(path)
  local lines = {}
  for i, sheet in ipairs(sheets) do
    if i > 1 then
      lines[#lines + 1] = ''
    end
    lines[#lines + 1] = '## ' .. sheet.name
    lines[#lines + 1] = ''
    local xml = unzip(path, sheet.target)
    vim.list_extend(lines, xml and render_sheet(xml, strings) or { '_(sheet could not be read)_' })
  end
  return lines
end

---------------------------------------------------------------------------
-- DOCX
---------------------------------------------------------------------------

local function render_paragraph(p)
  -- Tabs and line breaks become text before collecting the `<w:t>` nodes.
  p = p:gsub('<w:tab/>', '<w:t>\t</w:t>'):gsub('<w:br[^>]*/>', '<w:t>\n</w:t>')
  local text = text_nodes(p, 'w:t')
  local style = p:match('<w:pStyle%s+w:val="([^"]*)"') or ''
  local level = style:match('^[Hh]eading%s*(%d)$') or style:match('^[Tt]itre%s*(%d)$')
  if style == 'Title' then
    level = '1'
  end
  if text:match('^%s*$') then
    return ''
  end
  if level then
    return string.rep('#', math.min(tonumber(level), 6)) .. ' ' .. text
  end
  if p:find('<w:numPr>', 1, true) then
    local ilvl = tonumber(p:match('<w:ilvl%s+w:val="(%d+)"')) or 0
    return string.rep('  ', ilvl) .. '- ' .. text
  end
  return text
end

local function render_table(tbl)
  local rows, ncols = {}, 0
  for tr in tbl:gmatch('<w:tr[ >].-</w:tr>') do
    local row = {}
    for tc in tr:gmatch('<w:tc>.-</w:tc>') do
      local parts = {}
      for p in tc:gmatch('<w:p[ >].-</w:p>') do
        local t = render_paragraph(p)
        if t ~= '' then
          parts[#parts + 1] = t
        end
      end
      row[#row + 1] = clean_cell(table.concat(parts, ' '))
    end
    ncols = math.max(ncols, #row)
    rows[#rows + 1] = row
  end
  if #rows == 0 then
    return {}
  end
  local header = table.remove(rows, 1)
  return md_table(header, rows, ncols)
end

local function render_docx(path)
  local xml = unzip(path, 'word/document.xml')
  if not xml then
    return { 'Could not read word/document.xml from ' .. path }
  end
  local lines, pos = {}, 1
  while true do
    local p_s = xml:find('<w:p[ >]', pos)
    local t_s = xml:find('<w:tbl>', pos, true)
    if not p_s and not t_s then
      break
    end
    if t_s and (not p_s or t_s < p_s) then
      local _, t_e = xml:find('</w:tbl>', t_s, true)
      if not t_e then
        break
      end
      lines[#lines + 1] = ''
      vim.list_extend(lines, render_table(xml:sub(t_s, t_e)))
      lines[#lines + 1] = ''
      pos = t_e + 1
    else
      local _, p_e = xml:find('</w:p>', p_s, true)
      if not p_e then
        break
      end
      local text = render_paragraph(xml:sub(p_s, p_e))
      -- Blank line between paragraphs, but keep list items tight.
      if text ~= '' then
        if not text:match('^%s*%- ') and #lines > 0 and lines[#lines] ~= '' then
          lines[#lines + 1] = ''
        end
        lines[#lines + 1] = text
      end
      pos = p_e + 1
    end
  end
  if #lines == 0 then
    return { '_(empty document)_' }
  end
  return lines
end

---------------------------------------------------------------------------
-- Buffer
---------------------------------------------------------------------------

---Fills the current buffer (the one `BufReadCmd` fired for) with the rendering.
---@param buf integer
function M.open(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  local ext = path:match('%.(%w+)$') or ''
  ext = ext:lower()

  local lines
  if vim.fn.executable('unzip') ~= 1 then
    lines = { '`unzip` was not found in PATH: it is required to view Office files.' }
  elseif ext == 'docx' then
    lines = render_docx(path)
  else
    lines = render_xlsx(path)
  end

  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
  vim.bo[buf].readonly = true
  vim.bo[buf].filetype = 'markdown'
  vim.wo.wrap = false
  vim.keymap.set('n', 'q', '<cmd>bdelete<CR>', { buffer = buf, desc = 'Close the viewer' })
end

function M.setup()
  -- Neovim's bundled zip.vim also claims these extensions (they are zip files).
  -- It reads `g:zipPlugin_ext` when it loads (after this config), so drop ours.
  local ours = { ['*.xlsx'] = true, ['*.xlsm'] = true, ['*.docx'] = true }
  local default = vim.g.zipPlugin_ext
    or '*.aar,*.apk,*.docm,*.docx,*.dotm,*.dotx,*.ear,*.epub,*.jar,*.kmz,*.odb,*.odc,*.odf,*.odg,*.odi,*.odm,*.odp,*.ods,*.odt,*.otc,*.otf,*.otg,*.oth,*.oti,*.otp,*.ots,*.ott,*.oxt,*.pkpass,*.potm,*.potx,*.ppam,*.ppsm,*.ppsx,*.pptm,*.pptx,*.sldx,*.thmx,*.war,*.whl,*.xap,*.xlam,*.xlsb,*.xlsm,*.xlsx,*.xltm,*.xltx,*.xpi,*.zip'
  vim.g.zipPlugin_ext = table.concat(
    vim.tbl_filter(function(ext)
      return not ours[ext]
    end, vim.split(default, ',', { plain = true })),
    ','
  )
  vim.api.nvim_create_autocmd('BufReadCmd', {
    group = vim.api.nvim_create_augroup('OfficeViewer', { clear = true }),
    pattern = { '*.xlsx', '*.xlsm', '*.docx' },
    callback = function(args)
      M.open(args.buf)
    end,
  })
end

return M
