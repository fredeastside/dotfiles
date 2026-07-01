return {
  'mrjones2014/smart-splits.nvim',
  -- Not lazy-loaded: loading at startup lets the plugin set the IS_NVIM user var,
  -- which WezTerm reads to detect Neovim (robust over SSH, no process-name latency).
  lazy = false,
  config = function()
    local ss = require('smart-splits')
    ss.setup({
      -- When in a floating window (e.g. lazygit), forward moves to the
      -- multiplexer (WezTerm) so Ctrl+hjkl still jumps between panes.
      float_win_behavior = 'mux',
    })

    -- Move between Neovim splits; cross into WezTerm panes at the edge.
    -- Mapped in normal AND terminal mode so it also works inside terminal
    -- buffers like lazygit (which run in terminal mode).
    vim.keymap.set({ 'n', 't' }, '<C-h>', ss.move_cursor_left, { desc = 'Move to split/pane left' })
    vim.keymap.set({ 'n', 't' }, '<C-j>', ss.move_cursor_down, { desc = 'Move to split/pane down' })
    vim.keymap.set({ 'n', 't' }, '<C-k>', ss.move_cursor_up, { desc = 'Move to split/pane up' })
    vim.keymap.set({ 'n', 't' }, '<C-l>', ss.move_cursor_right, { desc = 'Move to split/pane right' })

    -- Resize splits/panes with Option(META)+hjkl.
    vim.keymap.set('n', '<A-h>', ss.resize_left, { desc = 'Resize split left' })
    vim.keymap.set('n', '<A-j>', ss.resize_down, { desc = 'Resize split down' })
    vim.keymap.set('n', '<A-k>', ss.resize_up, { desc = 'Resize split up' })
    vim.keymap.set('n', '<A-l>', ss.resize_right, { desc = 'Resize split right' })
  end,
}
