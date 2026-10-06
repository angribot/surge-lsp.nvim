return {
  cmd = { 'surge-cli', 'lsp' },
  filetypes = { 'sgconf' },
  root_dir = function(bufnr, on_dir)
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name:match('%.lsr$') or name:match('%.list$') then return end
    on_dir(nil)
  end,
  get_language_id = function(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)
    return name:match('%.sgmodule$') and 'surge-module' or 'surge'
  end,
}
