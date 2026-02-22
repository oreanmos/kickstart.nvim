return {
  'ThePrimeagen/git-worktree.nvim',
  dependencies = { 'nvim-telescope/telescope.nvim' },
  config = function()
    require('git-worktree').setup()
    require('telescope').load_extension 'git_worktree'

    vim.keymap.set('n', '<leader>gwl', function() require('telescope').extensions.git_worktree.git_worktrees() end, { desc = 'Git: List Worktrees' })
    vim.keymap.set('n', '<leader>gwc', function() require('telescope').extensions.git_worktree.create_git_worktree() end, { desc = 'Git: Create Worktree' })
  end,
}
