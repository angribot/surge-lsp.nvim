if vim.g.loaded_surge_lsp then return end
vim.g.loaded_surge_lsp = true

local home = vim.fn.expand('~')
local patterns = {}
for _, dir in ipairs({
  home .. '/Library/Application Support/Surge/Profiles/',
  home .. '/Library/Mobile Documents/iCloud~com~nssurge~inc/Documents/',
}) do
  for _, extension in ipairs({ 'conf', 'dconf' }) do
    patterns[vim.pesc(dir) .. '.*%.' .. extension] = 'sgconf'
  end
end

vim.filetype.add({
  extension = { sgmodule = 'sgconf' },
  pattern = patterns,
})
