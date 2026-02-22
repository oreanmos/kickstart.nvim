return {
  {
    'nvim-lua/plenary.nvim',
    optional = true,
    config = function()
      local M = {}
      local wrapper_root = vim.fn.expand '$HOME/.local/share/nvim-distrobox-tools'
      local base_path = vim.env.PATH or ''
      local markers = { '.git', '.nvim-distrobox' }
      local tools = { 'rust-analyzer', 'codelldb', 'netcoredbg', 'dotnet', 'node', 'npm', 'cargo', 'rustc' }

      local function split_path(path)
        local parts = {}
        for item in string.gmatch(path, '([^:]+)') do
          table.insert(parts, item)
        end
        return parts
      end

      local function strip_wrapper_paths(path)
        local kept = {}
        for _, item in ipairs(split_path(path)) do
          if not vim.startswith(item, wrapper_root .. '/') then
            table.insert(kept, item)
          end
        end
        return table.concat(kept, ':')
      end

      local function ensure_wrappers(box_name)
        local dir = wrapper_root .. '/' .. box_name
        vim.fn.mkdir(dir, 'p')

        for _, tool in ipairs(tools) do
          local path = dir .. '/' .. tool
          local script = table.concat({
            '#!/usr/bin/env bash',
            'exec distrobox enter ' .. vim.fn.shellescape(box_name) .. ' -- ' .. tool .. ' "$@"',
            '',
          }, '\n')
          vim.fn.writefile(vim.split(script, '\n'), path)
          vim.fn.system { 'chmod', '+x', path }
        end

        return dir
      end

      local function apply_box(box_name)
        if box_name == '' then
          vim.env.PATH = strip_wrapper_paths(base_path)
          vim.g.distrobox_project_name = nil
          return
        end

        if vim.fn.executable 'distrobox' == 0 then
          vim.notify('distrobox not found on PATH; cannot enable project distrobox mode', vim.log.levels.WARN)
          return
        end

        local wrapper_dir = ensure_wrappers(box_name)
        vim.env.PATH = wrapper_dir .. ':' .. strip_wrapper_paths(base_path)
        vim.g.distrobox_project_name = box_name
      end

      local function project_root()
        return vim.fs.root(0, markers) or vim.fn.getcwd()
      end

      local function read_project_box()
        local root = project_root()
        local cfg = root .. '/.nvim-distrobox'
        if vim.fn.filereadable(cfg) == 0 then
          return ''
        end
        local lines = vim.fn.readfile(cfg)
        return vim.trim(lines[1] or '')
      end

      function M.refresh()
        apply_box(read_project_box())
      end

      vim.api.nvim_create_user_command('DistroboxProject', function(opts)
        local arg = vim.trim(opts.args or '')
        local root = project_root()
        local cfg = root .. '/.nvim-distrobox'

        if arg == '' then
          M.refresh()
          local active = vim.g.distrobox_project_name or 'none'
          vim.notify('Project distrobox: ' .. active)
          return
        end

        if arg == 'off' then
          vim.fn.delete(cfg)
          apply_box ''
          vim.notify('Disabled project distrobox for ' .. root)
          return
        end

        vim.fn.writefile({ arg }, cfg)
        apply_box(arg)
        vim.notify('Project distrobox set to ' .. arg)
      end, {
        nargs = '?',
        complete = function()
          local names = {}
          if vim.fn.executable 'distrobox' == 1 then
            local out = vim.fn.systemlist 'distrobox list --no-color'
            for i = 2, #out do
              local name = vim.split(vim.trim(out[i]), '%s+')[1]
              if name and name ~= '' then
                table.insert(names, name)
              end
            end
          end
          table.insert(names, 'off')
          return names
        end,
      })

      vim.api.nvim_create_autocmd({ 'VimEnter', 'DirChanged' }, {
        callback = M.refresh,
      })
    end,
  },
}
