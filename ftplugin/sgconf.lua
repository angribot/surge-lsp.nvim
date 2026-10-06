if vim.b.did_ftplugin then return end
vim.b.did_ftplugin = true
vim.bo.commentstring = '# %s'
vim.b.undo_ftplugin = 'setlocal commentstring<'
