-- Independently implemented recognition, not Surge configuration validation.
local M = {}
local limit = 65536
local rule_types = {}
for word in ([[DOMAIN DOMAIN-SUFFIX DOMAIN-KEYWORD DOMAIN-WILDCARD
IP-CIDR IP-CIDR6 IP-ASN GEOIP SRC-IP DEST-PORT SRC-PORT IN-PORT PROCESS-NAME
PROTOCOL USER-AGENT URL-REGEX SUBNET DEVICE-NAME MAC-ADDRESS HOSTNAME-TYPE
CELLULAR-CARRIER CELLULAR-RADIO]]):gmatch('%S+') do
  rule_types[word] = true
end
local options = { ['no-resolve'] = true, ['extended-matching'] = true,
  ['pre-matching'] = true, debug = true }

local function trim(s) return vim.trim(s) end
local function comment(s)
  return s:sub(1, 1) == '#' or s:sub(1, 1) == ';' or s:sub(1, 2) == '//'
end

-- Fetch only the bounded prefix; a boundary line is never used as evidence.
function M.prefix(buf)
  local first, last = 0, math.min(vim.api.nvim_buf_line_count(buf), limit)
  -- Find the last complete line without allocating an oversized line or buffer.
  while first < last do
    local middle = math.floor((first + last + 1) / 2)
    if vim.api.nvim_buf_get_offset(buf, middle) <= limit then
      first = middle
    else
      last = middle - 1
    end
  end
  return vim.api.nvim_buf_get_lines(buf, 0, first, false)
end

local function valid_options(rest)
  rest = trim(rest)
  while rest ~= '' and not comment(rest) do
    local option, tail = rest:match('^,%s*([a-z-]+)(.*)$')
    if not options[option] then return false end
    rest = trim(tail)
  end
  return true
end

local function rule(line)
  local kind, value = line:match('^([A-Z][A-Z0-9-]*)%s*,%s*(.*)$')
  if not rule_types[kind] or not value or value == '' then return false end
  local quote = value:sub(1, 1)
  if quote == '"' or quote == "'" then
    local i = 2
    while i <= #value do
      local char = value:sub(i, i)
      if char == '\\' then
        i = i + 2
      elseif char == quote then
        if i > 2 and valid_options(value:sub(i + 1)) then return true end
        break
      else
        i = i + 1
      end
    end
  end
  -- Unquoted conditions remain permissive; recognition is not validation.
  -- An inline comment can itself contain commas.
  local stop = #value + 1
  for _, marker in ipairs({ '#', ';', '//' }) do
    stop = math.min(stop, value:find(marker, 1, true) or stop)
  end
  local condition = stop > 1 and value:sub(1, stop - 1) or value
  local field, rest = condition:match('^([^,]+)(.*)$')
  return field ~= nil and trim(field) ~= '' and valid_options(rest)
end

function M.detect(path, lines)
  local ext = (vim.fs.basename(path):match('%.([^.]*)$') or ''):lower()
  if ext == 'sgmodule' then return 'surge_module' end
  local module_candidate = ext == 'conf' or ext == 'txt' or ext == 'module' or ext == ''
  local sections, header, count, rules = {}, true, 0, true
  for i, raw in ipairs(lines) do
    if i == 1 then raw = raw:gsub('^\239\187\191', '') end
    if raw:match('^[\t ]*%[') then header = false end
    if header and module_candidate and raw:match('^[\t ]*#!name[\t ]*=[\t ]*%S') then
      return 'surge_module'
    end
    local section, tail = raw:match('^%s*%[([^%]]+)%]%s*(.*)$')
    if section and (tail == '' or comment(tail)) then sections[trim(section)] = true end
    local line = trim(raw)
    if rules and count < 20 and line ~= '' and not comment(line) then
      if rule(line) then count = count + 1 else rules = false end
    end
  end
  local normalized = path:gsub('\\', '/')
  if ext == 'conf' and (
    normalized:find('/Library/Application Support/Surge/Profiles/', 1, true)
    or normalized:find('/Library/Mobile Documents/iCloud~com~nssurge~inc/Documents/Profiles/', 1, true)
    or (sections.Rule and (sections.Proxy or sections['Proxy Group']))
  ) then return 'surge' end
  if rules and count >= 2 then return 'surge_ruleset' end
end

function M.match(path, buf)
  if vim.g.surge_auto_detect == false or not buf or not vim.api.nvim_buf_is_valid(buf)
    or vim.bo[buf].buftype ~= '' or vim.bo[buf].filetype ~= ''
    or path == '' or path:match('^%a[%w+.-]*://') then return end
  return M.detect(path, M.prefix(buf))
end

return M
