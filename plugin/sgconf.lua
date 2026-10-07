if vim.g.loaded_surge_lsp then return end
vim.g.loaded_surge_lsp = true

vim.filetype.add({
  extension = { sgconf = 'surge', dconf = 'surge', sgmodule = 'surge_module' },
  filename = { ['Surge.conf'] = 'surge' },
  pattern = {
    ['.+'] = { function(path, buf)
      return require('surge.detect').match(path, buf)
    end, { priority = -math.huge } },
  },
})

-- Reconsider new/untyped files after editing; never replace a chosen filetype.
vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
  group = vim.api.nvim_create_augroup('surge_detection', { clear = true }),
  callback = function(ev)
    if vim.bo[ev.buf].filetype ~= '' then return end
    local ft = vim.filetype.match({ buf = ev.buf })
    if ft == 'surge' or ft == 'surge_module' or ft == 'surge_ruleset' then
      vim.bo[ev.buf].filetype = ft
    end
  end,
})
