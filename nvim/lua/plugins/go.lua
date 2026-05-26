return {
  {
    'ray-x/go.nvim',
    dependencies = { -- optional packages
      'ray-x/guihua.lua',
      'neovim/nvim-lspconfig',
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('go').setup {
        lsp_inlay_hints = {
          enable = false,
        },
        lsp_codelens = false,
      }
      local format_sync_grp = vim.api.nvim_create_augroup('GoImport', {})
      vim.api.nvim_create_autocmd('BufWritePre', {
        pattern = '*.go',
        callback = function()
          require('go.format').goimport()
        end,
        group = format_sync_grp,
      })
    end,
    event = { 'CmdlineEnter' },
    ft = { 'go', 'gomod' },
    build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
  },
  {
    'ray-x/lsp_signature.nvim',
    event = 'VeryLazy',
    opts = {},
    build = 'git -C . checkout -- doc/tags 2>/dev/null; echo doc/tags >> .git/info/exclude',
    config = function(_, opts)
      require('lsp_signature').setup(opts)
    end,
  },
}
