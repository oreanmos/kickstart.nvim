return {
  {
    'mrcjkb/rustaceanvim',
    version = '^6',
    ft = { 'rust' },
    init = function()
      vim.g.rustaceanvim = {
        server = {
          default_settings = {
            ['rust-analyzer'] = {
              cargo = { allFeatures = true },
              checkOnSave = true,
            },
          },
        },
      }

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'rust',
        callback = function(event)
          local map = function(lhs, rhs, desc)
            vim.keymap.set('n', lhs, rhs, { buffer = event.buf, desc = desc })
          end

          map('<leader>rr', function() vim.cmd.RustLsp 'runnables' end, 'Rust: Runnables')
          map('<leader>rd', function() vim.cmd.RustLsp 'debuggables' end, 'Rust: Debuggables')
        end,
      })
    end,
  },
  {
    'saecki/crates.nvim',
    event = { 'BufRead Cargo.toml' },
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {},
  },
  {
    'vxpm/ferris.nvim',
    ft = { 'rust' },
    opts = {},
  },
}
