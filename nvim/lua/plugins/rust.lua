return {
  {
    'mrcjkb/rustaceanvim',
    version = '^5', -- Recommended
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

      -- Auto-import unambiguous imports on save
      vim.api.nvim_create_autocmd('BufWritePre', {
        pattern = '*.rs',
        callback = function(args)
          local clients = vim.lsp.get_clients { bufnr = args.buf, name = 'rust_analyzer' }
          if #clients == 0 then
            return
          end
          local client = clients[1]

          local uri = vim.uri_from_bufnr(args.buf)

          -- Helper: extract text edits for current buffer from a workspace edit
          local function collect_edits(workspace_edit)
            local edits = {}
            local changes = workspace_edit.changes or {}
            if changes[uri] then
              for _, e in ipairs(changes[uri]) do
                table.insert(edits, e)
              end
            end
            for _, dc in ipairs(workspace_edit.documentChanges or {}) do
              if dc.textDocument and dc.textDocument.uri == uri then
                for _, e in ipairs(dc.edits or {}) do
                  table.insert(edits, e)
                end
              end
            end
            return edits
          end

          -- Helper: deduplicate text edits by range+content
          local function dedup_edits(edits)
            local seen = {}
            local unique = {}
            for _, e in ipairs(edits) do
              local key = string.format('%d:%d-%d:%d=%s',
                e.range.start.line, e.range.start.character,
                e.range['end'].line, e.range['end'].character,
                e.newText)
              if not seen[key] then
                seen[key] = true
                table.insert(unique, e)
              end
            end
            return unique
          end

          -- 1. Auto-import: apply only unambiguous quickfix imports
          local lsp_diags = {}
          for _, d in ipairs(vim.diagnostic.get(args.buf)) do
            if d.user_data and d.user_data.lsp then
              table.insert(lsp_diags, d.user_data.lsp)
            end
          end
          if #lsp_diags > 0 then
            local params = {
              textDocument = vim.lsp.util.make_text_document_params(args.buf),
              context = {
                only = { 'quickfix' },
                diagnostics = lsp_diags,
              },
              range = {
                start = { line = 0, character = 0 },
                ['end'] = { line = vim.api.nvim_buf_line_count(args.buf), character = 0 },
              },
            }
            local result = client.request_sync('textDocument/codeAction', params, 3000, args.buf)
            if result and result.result then
              local all_edits = {}
              for _, action in ipairs(result.result) do
                if action.edit then
                  local _, count = (action.title or ''):gsub('`use ', '')
                  if count == 1 then
                    for _, e in ipairs(collect_edits(action.edit)) do
                      table.insert(all_edits, e)
                    end
                  end
                end
              end
              all_edits = dedup_edits(all_edits)
              if #all_edits > 0 then
                vim.lsp.util.apply_text_edits(all_edits, args.buf, client.offset_encoding)
              end
            end
          end

          -- 2. Remove unused imports
          local unused_diags = {}
          for _, d in ipairs(vim.diagnostic.get(args.buf)) do
            if d.user_data and d.user_data.lsp and (d.code == 'unused_imports' or d.message:match 'unused import') then
              table.insert(unused_diags, d.user_data.lsp)
            end
          end
          if #unused_diags > 0 then
            local fix_params = {
              textDocument = vim.lsp.util.make_text_document_params(args.buf),
              context = {
                only = { 'quickfix' },
                diagnostics = unused_diags,
              },
              range = {
                start = { line = 0, character = 0 },
                ['end'] = { line = vim.api.nvim_buf_line_count(args.buf), character = 0 },
              },
            }
            local fix_result = client.request_sync('textDocument/codeAction', fix_params, 3000, args.buf)
            if fix_result and fix_result.result then
              local all_edits = {}
              for _, action in ipairs(fix_result.result) do
                if action.edit and action.title and action.title:match 'remove' then
                  for _, e in ipairs(collect_edits(action.edit)) do
                    table.insert(all_edits, e)
                  end
                end
              end
              all_edits = dedup_edits(all_edits)
              if #all_edits > 0 then
                vim.lsp.util.apply_text_edits(all_edits, args.buf, client.offset_encoding)
              end
            end
          end
        end,
      })
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
        completion = {
          cmp = {
            enabled = true,
          },
        },
      }
      require('cmp').setup.buffer {
        sources = { { name = 'crates' } },
      }
    end,
  },
}
