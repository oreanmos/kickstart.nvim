return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'mason-org/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',
  },
  keys = {
    {
      '<F5>',
      function() require('dap').continue() end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<F10>',
      function() require('dap').step_over() end,
      desc = 'Debug: Step Over',
    },
    {
      '<F11>',
      function() require('dap').step_into() end,
      desc = 'Debug: Step Into',
    },
    {
      '<F12>',
      function() require('dap').step_out() end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>db',
      function() require('dap').toggle_breakpoint() end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>dB',
      function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end,
      desc = 'Debug: Set Conditional Breakpoint',
    },
    {
      '<leader>du',
      function() require('dapui').toggle() end,
      desc = 'Debug: Toggle UI',
    },
    {
      '<leader>dr',
      function() require('dap').repl.open() end,
      desc = 'Debug: Open REPL',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      automatic_installation = true,
      ensure_installed = { 'codelldb', 'netcoredbg' },
      handlers = {},
    }

    dapui.setup()
    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close
  end,
}
