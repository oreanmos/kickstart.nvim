return {
  'akinsho/toggleterm.nvim',
  version = '*',
  opts = {
    direction = 'vertical',
    size = 70,
    shade_terminals = true,
  },
  config = function(_, opts)
    require('toggleterm').setup(opts)
    local Terminal = require('toggleterm.terminal').Terminal

    local kilo = Terminal:new { cmd = 'kilo', direction = 'vertical', hidden = true }
    local claude = Terminal:new { cmd = 'claude', direction = 'vertical', hidden = true }
    local codex = Terminal:new { cmd = 'codex', direction = 'vertical', hidden = true }

    vim.keymap.set('n', '<leader>ak', function() kilo:toggle() end, { desc = 'AI: Toggle Kilo CLI' })
    vim.keymap.set('n', '<leader>ac', function() claude:toggle() end, { desc = 'AI: Toggle Claude CLI' })
    vim.keymap.set('n', '<leader>ao', function() codex:toggle() end, { desc = 'AI: Toggle Codex CLI' })
  end,
}
