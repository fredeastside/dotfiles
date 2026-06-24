return {
  {
    'kevinhwang91/nvim-ufo',
    dependencies = { 'kevinhwang91/promise-async' },
    event = 'BufReadPost',
    opts = {
      filetype_exclude = { 'help', 'alpha', 'dashboard', 'neo-tree', 'Trouble', 'lazy', 'mason' },
      -- Use treesitter as the fold provider so comment blocks (and language
      -- constructs) fold; fall back to indent when no parser is available.
      provider_selector = function(_, _, _)
        return { 'treesitter', 'indent' }
      end,
    },
    config = function(_, opts)
      -- Fold options ufo expects. Start fully unfolded; fold manually with zM/zc.
      vim.opt.foldcolumn = '1' -- show a small fold column with fold markers
      vim.opt.foldlevel = 99
      vim.opt.foldlevelstart = 99
      vim.opt.foldenable = true

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('local_detach_ufo', { clear = true }),
        pattern = opts.filetype_exclude,
        callback = function()
          require('ufo').detach()
        end,
      })

      local ufo = require('ufo')
      ufo.setup(opts)

      -- Fold every multi-line comment in the buffer, leaving other folds open.
      -- Relies on the comment fold ranges that ufo's treesitter provider builds
      -- (see queries/<lang>/folds.scm); it only *closes* folds that already exist.
      local comment_query = {
        rust = '[(line_comment)+ @c (block_comment) @c]',
        -- default below covers go, lua, c, etc. whose comment node is `comment`
      }
      local function fold_all_comments()
        local bufnr = vim.api.nvim_get_current_buf()
        local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
        if not ok or not parser then
          return
        end
        parser:parse()

        -- Collect every comment's [start, end] row. The `+` quantifier does NOT
        -- coalesce captures, so each line comment arrives as its own one-line
        -- node; we merge adjacent ones into runs below.
        local intervals = {}
        parser:for_each_tree(function(tree, ltree)
          local lang = ltree:lang()
          local qs = comment_query[lang] or '((comment)+ @c)'
          local ok2, query = pcall(vim.treesitter.query.parse, lang, qs)
          if not ok2 then
            return
          end
          for _, node in query:iter_captures(tree:root(), bufnr) do
            local srow, _, erow, ecol = node:range()
            if ecol == 0 then
              erow = erow - 1
            end
            intervals[#intervals + 1] = { srow, erow }
          end
        end)

        table.sort(intervals, function(a, b)
          return a[1] < b[1]
        end)

        -- Merge contiguous/overlapping comment lines into runs, then close the
        -- fold at the start of any run that spans more than one line. Isolated
        -- single-line comments are left untouched.
        local last
        for _, r in ipairs(intervals) do
          if last and r[1] <= last[2] + 1 then
            last[2] = math.max(last[2], r[2])
          else
            if last and last[2] > last[1] then
              pcall(vim.cmd, (last[1] + 1) .. 'foldclose')
            end
            last = { r[1], r[2] }
          end
        end
        if last and last[2] > last[1] then
          pcall(vim.cmd, (last[1] + 1) .. 'foldclose')
        end
      end

      vim.api.nvim_create_user_command('FoldComments', fold_all_comments, { desc = 'Fold all comments' })

      -- Keymaps
      vim.keymap.set('n', 'zR', ufo.openAllFolds, { desc = 'Open all folds' })
      vim.keymap.set('n', 'zM', ufo.closeAllFolds, { desc = 'Close all folds' })
      vim.keymap.set('n', 'zr', ufo.openFoldsExceptKinds, { desc = 'Open folds except kinds' })
      vim.keymap.set('n', 'zm', ufo.closeFoldsWith, { desc = 'Close folds with' })
      vim.keymap.set('n', '<leader>zc', fold_all_comments, { desc = 'Fold all comments' })
    end,
  },
}
