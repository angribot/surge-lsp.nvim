return {
  cmd = { '/Applications/Surge.app/Contents/Applications/surge-cli', 'lsp' },
  filetypes = { 'surge', 'surge_module', 'surge_ruleset', 'sgconf' },
  root_dir = function(_, on_dir) on_dir(nil) end,
  get_language_id = function(bufnr, filetype)
    local ids = { surge = 'surge', surge_module = 'surge-module', surge_ruleset = 'surge-ruleset' }
    if filetype == 'sgconf' then
      return vim.api.nvim_buf_get_name(bufnr):lower():match('%.sgmodule$') and 'surge-module' or 'surge'
    end
    return ids[filetype] or 'surge'
  end,
}
