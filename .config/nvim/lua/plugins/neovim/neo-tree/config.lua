local M = {}

M.setup = function()
  local map = vim.keymap.set

  vim.cmd([[ let g:neo_tree_remove_legacy_commands = 1 ]])

  map("n", "<leader>e", ":Neotree toggle reveal float<CR>", { silent = true, noremap = false })
  map("n", "<leader>ge", ":Neotree float git_status<CR>", { silent = true, noremap = false })
  map("n", "<leader>be", ":Neotree float buffers<CR>", { silent = true, noremap = false })

  print(NeoUtils.icons.git.added)

  require("neo-tree").setup({
    use_popups_for_input = true,
    default_component_configs = {
      git_status = {
        symbols = {
          -- Change type
          added = NeoUtils.icons.git.added,
          modified = NeoUtils.icons.git.move,
          deleted = NeoUtils.icons.git.removed,
          renamed = NeoUtils.icons.git.rename,
          -- Status type
          untracked = NeoUtils.icons.git.untracked,
          ignored = NeoUtils.icons.git.ignored,
          unstaged = NeoUtils.icons.git.unstaged,
          staged = NeoUtils.icons.git.staged,
          conflict = NeoUtils.icons.git.config,
        },
      },
    },
    enable_diagnostics = true,
    event_handlers = {
      {
        event = "neo_tree_buffer_enter",
        handler = function()
          NeoUtils.cursor.hideCursor()
        end,
      },
      {
        event = "neo_tree_buffer_leave",
        handler = function()
          -- Make this whatever your current Cursor highlight group is.
          NeoUtils.cursor.restoreCursor()
        end,
      },
      {
        event = "neo_tree_popup_buffer_enter",
        handler = function()
          -- Make this whatever your current Cursor highlight group is.
          NeoUtils.cursor.restoreCursor()
        end,
      },
      {
        event = "neo_tree_window_after_close",
        handler = function()
          --auto close
          NeoUtils.cursor.restoreCursor()
          NeoUtils.layout.autoRefresh()
        end,
      },
    },
    source_selector = {
      truncation_character = "...",
      winbar = false,
      statusbar = false,
    },
    window = {
      width = 50,
      mappings = {
        ["<cr>"] = "open",
        ["l"] = "open",
        ["<esc>"] = "close_window",
        ["P"] = { "toggle_preview", config = { use_float = true } },
        ["S"] = "open_vsplit",
        ["s"] = "vsplit_with_window_picker",
        ["t"] = "open_tabnew",
        ["h"] = "close_node",
        ["z"] = "close_all_nodes",
        ["a"] = {
          "add",
          -- this command supports BASH style brace expansion ("x{a,b,c}" -> xa,xb,xc). see `:h neo-tree-file-actions` for details
          -- some commands may take optional config options, see `:h neo-tree-mappings` for details
          config = {
            show_path = "none", -- "none", "relative", "absolute"
          },
        },
        ["A"] = "add_directory", -- also accepts the optional config.show_path option like "add". this also supports BASH style brace expansion.
        ["d"] = "delete",
        ["r"] = "rename",
        ["y"] = "copy_to_clipboard",
        ["x"] = "cut_to_clipboard",
        ["p"] = "paste_from_clipboard",
        ["c"] = "copy", -- takes text input for destination, also accepts the optional config.show_path option like "add":
        ["m"] = "move", -- takes text input for destination, also accepts the optional config.show_path option like "add".
        ["q"] = "close_window",
        ["R"] = "refresh",
        ["?"] = "show_help",
        ["<"] = "prev_source",
        [">"] = "next_source",
      },
      -- popup = {
      --   size = function(state)
      --     local root_name = vim.fn.fnamemodify(state.path, ":~")
      --     local root_len = string.len(root_name) + 4
      --
      --     return {
      --       width = math.max(root_len, 70),
      --       height = vim.o.lines - 6,
      --     }
      --   end,
      -- },
    },
    filesystem = {
      find_command = "fd",
      find_args = {
        fd = {
          "--exclude",
          ".git",
          "--exclude",
          "node_modules",
          "--exclude",
          "Pods",
          "dist",
          "build",
          ".yarn",
        },
      },
      bind_to_cwd = true,
      filtered_items = {
        hide_dotfiles = false,
        hide_gitignored = false,
      },
      follow_current_file = {
        enabled = true, -- This will find and focus the file in the active buffer every time
        --              -- the current file is changed while the tree is open.
        leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
      },
      -- time the current file is changed while the tree is open.
      group_empty_dirs = false, -- when true, empty folders will be grouped together
      hijack_netrw_behavior = "open_default", -- netrw disabled, opening a directory opens neo-tree
      -- in whatever position is specified in window.position
      -- "open_current",  -- netrw disabled, opening a directory opens within the
      -- window like netrw would, regardless of window.position
      -- "disabled",    -- netrw left alone, neo-tree does not handle opening dirs
      use_libuv_file_watcher = true, -- This will use the OS level file watchers to detect changes
      -- instead of relying on nvim autocmd events.
      window = {
        fuzzy_finder_mappings = { -- define keymaps for filter popup window in fuzzy_finder_mode
          ["<down>"] = "move_cursor_down",
          ["<up>"] = "move_cursor_up",
          ["<C-j>"] = "move_cursor_down",
          ["<C-k>"] = "move_cursor_up",
        },
        mappings = {
          ["o"] = "system_open",
        },
      },
      commands = {
        system_open = function(state)
          local node = state.tree:get_node()
          local path = node:get_id()
          -- macOs: open file in default application in the background.
          -- Probably you need to adapt the Linux recipe for manage path with spaces. I don't have a mac to try.
          vim.api.nvim_command("silent !open -g " .. path)
          -- Linux: open file in default application
          vim.api.nvim_command(string.format("silent !xdg-open '%s'", path))
        end,
        -- Override delete to use trash instead of rm
        delete = function(state)
          local inputs = require("neo-tree.ui.inputs")
          local path = state.tree:get_node().path
          local msg = "Are you sure you want to trash " .. path
          inputs.confirm(msg, function(confirmed)
            if not confirmed then
              return
            end

            vim.fn.system({ "trash", vim.fn.fnameescape(path) })
            require("neo-tree.sources.manager").refresh(state.name)
          end)
        end,
        -- over write default 'delete_visual' command to 'trash' x n.
        delete_visual = function(state, selected_nodes)
          local inputs = require("neo-tree.ui.inputs")

          -- get table items count
          function GetTableLen(tbl)
            local len = 0
            for _ in pairs(tbl) do
              len = len + 1
            end
            return len
          end

          local count = GetTableLen(selected_nodes)
          local msg = "Are you sure you want to trash " .. count .. " files ?"
          inputs.confirm(msg, function(confirmed)
            if not confirmed then
              return
            end
            for _, node in ipairs(selected_nodes) do
              vim.fn.system({ "trash", vim.fn.fnameescape(node.path) })
            end
            require("neo-tree.sources.manager").refresh(state.name)
          end)
        end,
      },
    },
  })

  require("nvim-web-devicons").setup({})
end

return M
