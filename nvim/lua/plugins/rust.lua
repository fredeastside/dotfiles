return {
  {
    'mrcjkb/rustaceanvim',
    version = '^8',
    lazy = false, -- This plugin is already lazy
    ft = 'rust',
    config = function()
      require('mason').setup()

      local ok, codelldb = pcall(function()
        local mason_registry = require 'mason-registry'
        local pkg = mason_registry.get_package 'codelldb'
        return pkg:get_install_path()
      end)

      if ok and codelldb then
        local extension_path = codelldb .. '/extension/'
        local codelldb_path = extension_path .. 'adapter/codelldb'
        local liblldb_path = extension_path .. 'lldb/lib/liblldb.dylib'
        local cfg = require 'rustaceanvim.config'
        vim.g.rustaceanvim = {
          dap = {
            adapter = cfg.get_codelldb_adapter(codelldb_path, liblldb_path),
          },
        }
      end
    end,
  },
  {
    'rust-lang/rust.vim',
    ft = 'rust',
    init = function()
      vim.g.rustfmt_autosave = 1
    end,
  },
  {
    'saecki/crates.nvim',
    ft = { 'toml' },
    config = function()
      require('crates').setup {
        lsp = {
          enabled = true,
          actions = true,
          completion = true,
          hover = true,
        },
      }
    end,
  },
}
