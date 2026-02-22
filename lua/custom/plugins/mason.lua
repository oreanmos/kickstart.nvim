return {
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      opts.ensure_installed = opts.ensure_installed or {}

      local tools = { 'rust-analyzer', 'roslyn', 'codelldb', 'netcoredbg' }
      for _, tool in ipairs(tools) do
        if not vim.tbl_contains(opts.ensure_installed, tool) then
          table.insert(opts.ensure_installed, tool)
        end
      end

      return opts
    end,
  },
}
