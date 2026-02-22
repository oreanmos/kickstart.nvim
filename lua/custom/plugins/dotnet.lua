return {
  {
    'GustavEikaas/easy-dotnet.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'folke/snacks.nvim' },
    ft = { 'cs', 'vb', 'fsharp' },
    opts = {
      test_runner = {
        viewmode = 'float',
      },
    },
    config = function(_, opts)
      local ok, dotnet = pcall(require, 'easy-dotnet')
      if ok then
        dotnet.setup(opts)
      end

      local map = function(lhs, rhs, desc)
        vim.keymap.set('n', lhs, rhs, { desc = desc })
      end

      map('<leader>nb', '<cmd>Dotnet build<CR>', '.NET: Build')
      map('<leader>nr', '<cmd>Dotnet run<CR>', '.NET: Run')
      map('<leader>nt', '<cmd>Dotnet test<CR>', '.NET: Test')
    end,
  },
}
