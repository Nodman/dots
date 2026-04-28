return {
  -- Core DAP
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      -- DAP UI
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
        opts = {},
        config = function(_, opts)
          local dap = require("dap")
          local dapui = require("dapui")
          dapui.setup(opts)

          -- Auto-open/close UI with DAP sessions
          dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
          end
          dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
          end
          dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
          end
        end,
      },

      -- Python adapter
      {
        "mfussenegger/nvim-dap-python",
        ft = "python",
        config = function()
          local mason_debugpy = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
          local python = vim.fn.executable(mason_debugpy) == 1 and mason_debugpy or vim.fn.exepath("python3")
          require("dap-python").setup(python)
        end,
      },
    },

    keys = {
      -- Session control
      { "<leader>ds", function() require("dap").continue() end, desc = "Start / Continue" },
      { "<leader>dq", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>dr", function() require("dap").restart() end, desc = "Restart" },
      -- Step controls
      { "<leader>do", function() require("dap").step_over() end, desc = "Step Over" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step Out" },
      -- Breakpoints
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
        desc = "Conditional Breakpoint",
      },
      -- UI
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle UI" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = { "n", "v" } },
      -- REPL
      { "<leader>dR", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
    },

    config = function()
      -- DAP sign icons
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticError", numhl = "" })
      vim.fn.sign_define("DapLogPoint", { text = "◎", texthl = "DiagnosticInfo", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "→", texthl = "DiagnosticOk", linehl = "Visual", numhl = "" })

      -- Register which-key group
      require("which-key").add({ { "<leader>d", group = "debug" } })
    end,
  },

}
