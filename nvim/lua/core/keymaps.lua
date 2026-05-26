-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local keymap = vim.keymap

keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
-- [d and ]d for diagnostic navigation are provided by Neovim 0.11+ defaults
keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Custom keymaps
keymap.set('n', '<C-d>', '<C-d>zz')
keymap.set('n', '<C-u>', '<C-u>zz')
keymap.set('n', '<leader>la', '<cmd>lua vim.lsp.buf.code_action()<CR>', { desc = 'action' })

-- Yank file path and line number
keymap.set({ 'n', 'v' }, '<leader>yl', function()
  local path = vim.fn.expand '%:.'
  local s, e = vim.fn.line 'v', vim.fn.line '.'
  if s > e then s, e = e, s end
  local ref = s == e and (path .. ':' .. s) or (path .. ':' .. s .. '-' .. e)
  vim.fn.setreg('+', ref)
end, { desc = '[Y]ank file:[l]ine' })

-- window management
-- keymap.set('n', '<leader>sv', '<C-w>v', { desc = 'Split window vertically' }) -- split window vertically
-- keymap.set('n', '<leader>sh', '<C-w>s', { desc = 'Split window horizontally' }) -- split window horizontally
-- keymap.set('n', '<leader>se', '<C-w>=', { desc = 'Make splits equal size' }) -- make split windows equal width & height
-- keymap.set('n', '<leader>sx', '<cmd>close<CR>', { desc = 'Close current split' }) -- close current split window
